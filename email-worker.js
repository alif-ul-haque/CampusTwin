export default {
  async fetch(request, env, ctx) {
    const url = new URL(request.url);

    // ============================================================
    // CORS
    // ============================================================

    const corsHeaders = {
      "Access-Control-Allow-Origin": "*",
      "Access-Control-Allow-Methods": "POST, OPTIONS",
      "Access-Control-Allow-Headers": "Content-Type",
    };

    if (request.method === "OPTIONS") {
      return new Response(null, {
        status: 204,
        headers: corsHeaders,
      });
    }

    // ============================================================
    // HELPER: JSON RESPONSE
    // ============================================================

    function jsonResponse(data, status = 200) {
      return new Response(JSON.stringify(data), {
        status,
        headers: {
          "Content-Type": "application/json",
          ...corsHeaders,
        },
      });
    }

    // ============================================================
    // HELPER: BASE64URL ENCODE
    // ============================================================

    function base64UrlEncode(input) {
      let bytes;

      if (typeof input === "string") {
        bytes = new TextEncoder().encode(input);
      } else {
        bytes = input;
      }

      let binary = "";

      for (let i = 0; i < bytes.length; i++) {
        binary += String.fromCharCode(bytes[i]);
      }

      return btoa(binary)
        .replace(/\+/g, "-")
        .replace(/\//g, "_")
        .replace(/=+$/g, "");
    }

    // ============================================================
    // HELPER: IMPORT GOOGLE SERVICE ACCOUNT PRIVATE KEY
    // ============================================================

    async function importPrivateKey(privateKey) {
      const normalizedKey = privateKey
        .replace(/\\n/g, "\n")
        .replace(/-----BEGIN PRIVATE KEY-----/g, "")
        .replace(/-----END PRIVATE KEY-----/g, "")
        .replace(/\s/g, "");

      const binaryKey = Uint8Array.from(
        atob(normalizedKey),
        (char) => char.charCodeAt(0)
      );

      return crypto.subtle.importKey(
        "pkcs8",
        binaryKey.buffer,
        {
          name: "RSASSA-PKCS1-v1_5",
          hash: "SHA-256",
        },
        false,
        ["sign"]
      );
    }

    // ============================================================
    // HELPER: CREATE GOOGLE SERVICE ACCOUNT JWT
    // ============================================================

    async function createGoogleJWT(env) {
      if (!env.FIREBASE_CLIENT_EMAIL) {
        throw new Error("Missing FIREBASE_CLIENT_EMAIL");
      }

      if (!env.FIREBASE_PRIVATE_KEY) {
        throw new Error("Missing FIREBASE_PRIVATE_KEY");
      }

      const now = Math.floor(Date.now() / 1000);

      const header = {
        alg: "RS256",
        typ: "JWT",
      };

      const payload = {
        iss: env.FIREBASE_CLIENT_EMAIL,
        scope: "https://www.googleapis.com/auth/identitytoolkit",
        aud: "https://oauth2.googleapis.com/token",
        iat: now,
        exp: now + 3600,
      };

      const encodedHeader = base64UrlEncode(JSON.stringify(header));
      const encodedPayload = base64UrlEncode(JSON.stringify(payload));
      const unsignedToken = `${encodedHeader}.${encodedPayload}`;

      const privateKey = await importPrivateKey(env.FIREBASE_PRIVATE_KEY);

      const signature = await crypto.subtle.sign(
        { name: "RSASSA-PKCS1-v1_5" },
        privateKey,
        new TextEncoder().encode(unsignedToken)
      );

      return `${unsignedToken}.${base64UrlEncode(new Uint8Array(signature))}`;
    }

    // ============================================================
    // HELPER: GET GOOGLE ACCESS TOKEN
    // ============================================================

    async function getGoogleAccessToken(env) {
      const jwt = await createGoogleJWT(env);

      const tokenResponse = await fetch("https://oauth2.googleapis.com/token", {
        method: "POST",
        headers: {
          "Content-Type": "application/x-www-form-urlencoded",
        },
        body:
          `grant_type=${encodeURIComponent(
            "urn:ietf:params:oauth:grant-type:jwt-bearer"
          )}` +
          `&assertion=${encodeURIComponent(jwt)}`,
      });

      const tokenData = await tokenResponse.json();

      if (!tokenResponse.ok) {
        throw new Error(
          tokenData.error_description ||
            tokenData.error ||
            "Failed to obtain Google access token"
        );
      }

      if (!tokenData.access_token) {
        throw new Error("Google OAuth did not return an access token");
      }

      return tokenData.access_token;
    }

    // ============================================================
    // HELPER: GENERATE FIREBASE OOB LINK
    // ============================================================

    async function generateFirebaseOobLink(env, requestBody) {
      if (!env.FIREBASE_PROJECT_ID) {
        throw new Error("Missing FIREBASE_PROJECT_ID");
      }

      const accessToken = await getGoogleAccessToken(env);

      const endpoint =
        `https://identitytoolkit.googleapis.com/v1/projects/` +
        `${encodeURIComponent(env.FIREBASE_PROJECT_ID)}/accounts:sendOobCode`;

      const firebaseResponse = await fetch(endpoint, {
        method: "POST",
        headers: {
          "Content-Type": "application/json",
          Authorization: `Bearer ${accessToken}`,
        },
        body: JSON.stringify({
          ...requestBody,
          returnOobLink: true,
        }),
      });

      const firebaseData = await firebaseResponse.json();

      if (!firebaseResponse.ok) {
        throw new Error(
          firebaseData.error?.message || "Firebase sendOobCode request failed"
        );
      }

      if (!firebaseData.oobLink) {
        throw new Error("Firebase did not return an oobLink");
      }

      return firebaseData.oobLink;
    }

    // ============================================================
    // HELPER: SEND EMAIL THROUGH EMAILJS
    // ============================================================

    async function sendEmailJS(env, { email, actionLink, messageIntro, buttonText }) {
      if (!env.EMAILJS_SERVICE_ID) {
        throw new Error("Missing EMAILJS_SERVICE_ID");
      }

      if (!env.EMAILJS_TEMPLATE_ID) {
        throw new Error("Missing EMAILJS_TEMPLATE_ID");
      }

      if (!env.EMAILJS_PUBLIC_KEY) {
        throw new Error("Missing EMAILJS_PUBLIC_KEY");
      }

      const templateParams = {
        to_email: email,
        email: email,
        action_link: actionLink,
        message_intro: messageIntro,
        button_text: buttonText,
      };

      // user_id = PUBLIC KEY, accessToken = PRIVATE KEY.
      // NEVER put EMAILJS_PRIVATE_KEY in user_id.
      const emailJsPayload = {
        service_id: env.EMAILJS_SERVICE_ID,
        template_id: env.EMAILJS_TEMPLATE_ID,
        user_id: env.EMAILJS_PUBLIC_KEY,
        template_params: templateParams,
      };

      if (env.EMAILJS_PRIVATE_KEY) {
        emailJsPayload.accessToken = env.EMAILJS_PRIVATE_KEY;
      }

      const emailJsResponse = await fetch(
        "https://api.emailjs.com/api/v1.0/email/send",
        {
          method: "POST",
          headers: {
            "Content-Type": "application/json",
          },
          body: JSON.stringify(emailJsPayload),
        }
      );

      if (!emailJsResponse.ok) {
        const errorText = await emailJsResponse.text();
        throw new Error(`EmailJS error: ${errorText}`);
      }

      return true;
    }

    // ============================================================
    // 1. PASSWORD RESET
    // POST /send-password-reset
    // ============================================================

    if (request.method === "POST" && url.pathname === "/send-password-reset") {
      try {
        const body = await request.json();
        const email = body.email;

        if (!email) {
          return jsonResponse(
            { success: false, message: "Missing email parameter" },
            400
          );
        }

        const resetLink = await generateFirebaseOobLink(env, {
          requestType: "PASSWORD_RESET",
          email: email,
        });

        await sendEmailJS(env, {
          email: email,
          actionLink: resetLink,
          messageIntro:
            "A request has been initiated to reset the password for your CampusTwin account.",
          buttonText: "Reset Password",
        });

        return jsonResponse({
          success: true,
          message: "Password reset email sent successfully",
        });
      } catch (error) {
        return jsonResponse(
          { success: false, message: "Server Error", error: error.message },
          500
        );
      }
    }

    // ============================================================
    // 2. EMAIL VERIFICATION
    // POST /send-verification
    // ============================================================

    if (request.method === "POST" && url.pathname === "/send-verification") {
      try {
        const body = await request.json();

        const email = body.email;
        const idToken = body.idToken;

        if (!email) {
          return jsonResponse(
            { success: false, message: "Missing email parameter" },
            400
          );
        }

        if (!idToken) {
          return jsonResponse(
            { success: false, message: "Missing Firebase ID token" },
            401
          );
        }

        const verificationLink = await generateFirebaseOobLink(env, {
          requestType: "VERIFY_EMAIL",
          idToken: idToken,
        });

        await sendEmailJS(env, {
          email: email,
          actionLink: verificationLink,
          messageIntro:
            "Please verify your email address to activate your CampusTwin account.",
          buttonText: "Verify My Email",
        });

        return jsonResponse({
          success: true,
          message: "Verification email sent successfully",
        });
      } catch (error) {
        return jsonResponse(
          { success: false, message: "Server Error", error: error.message },
          500
        );
      }
    }

    // ============================================================
    // INVALID ROUTE
    // ============================================================

    return new Response("Method Not Allowed or Invalid Path", {
      status: 405,
      headers: corsHeaders,
    });
  },
};