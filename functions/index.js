const {setGlobalOptions} = require("firebase-functions");
const {onCall, HttpsError} = require("firebase-functions/v2/https");
const logger = require("firebase-functions/logger");
const admin = require("firebase-admin");

admin.initializeApp();
setGlobalOptions({maxInstances: 10});

const APP_NAME = "CampusTwin";
const LOGO_URL =
  "https://firebasestorage.googleapis.com/v0/b/campustwin-2a63e.appspot.com/o/Campus_Twin.png?alt=media";

/**
 * Branded, responsive email layout used by every mailer in this project.
 * The header shows the Campus Twin logo (hosted in Firebase Storage) with
 * APP_NAME as a fallback if the image is ever unavailable.
 */
function emailShell(title, bodyHtml) {
  return `
<!DOCTYPE html>
<html>
<body style="margin:0;padding:0;background:#f1f5f9;font-family:Segoe UI,Arial,sans-serif;">
  <div style="max-width:560px;margin:40px auto;background:#ffffff;border-radius:18px;overflow:hidden;box-shadow:0 6px 18px rgba(0,0,0,0.08);">
    <div style="background:linear-gradient(135deg,#163dDB,#2563eb,#22c1c3);padding:30px 24px;text-align:center;">
      <img src="${LOGO_URL}" alt="${APP_NAME}"
           width="92" height="92"
           style="border-radius:20px;background:#ffffff;padding:6px;display:inline-block;"
           onerror="this.style.display='none'"/>
      <p style="color:#ffffff;margin:14px 0 0;font-size:26px;font-weight:800;letter-spacing:-0.3px;">${APP_NAME}</p>
      <p style="color:rgba(255,255,255,0.85);margin:4px 0 0;font-size:13.5px;">Study, plan &amp; thrive</p>
    </div>
    <div style="padding:34px 34px 30px;">
      ${bodyHtml}
    </div>
    <div style="background:#f8fafc;padding:18px;text-align:center;border-top:1px solid #eef2f7;">
      <p style="color:#94a3b8;font-size:12px;margin:0;">&copy; ${new Date().getFullYear()} ${APP_NAME} Team &middot; Built for students</p>
    </div>
  </div>
</body>
</html>`;
}

function buttonHtml(label, link) {
  return `
      <div style="text-align:center;margin:30px 0;">
        <a href="${link}"
           style="background:#2563eb;color:#ffffff;text-decoration:none;
                  padding:14px 40px;border-radius:12px;font-weight:700;
                  display:inline-block;font-size:15px;box-shadow:0 4px 10px rgba(37,99,235,0.35);">
          ${label}
        </a>
      </div>`;
}

function linkBlock(link) {
  return `
      <p style="color:#64748b;font-size:13px;line-height:1.6;">
        Or copy this link into your browser:<br/>
        <a href="${link}" style="color:#2563eb;word-break:break-all;">${link}</a>
      </p>`;
}

function buildVerificationHtml(displayName, link) {
  const body = `
      <h2 style="color:#0f172a;margin-top:0;font-size:22px;letter-spacing:-0.2px;">Welcome to ${APP_NAME} 👋</h2>
      <p style="color:#334155;font-size:15px;line-height:1.7;">
        Hi <strong>${displayName || "there"}</strong>,<br/>
        Please confirm your email address so we know it's really you. It only takes a second.
      </p>
      ${buttonHtml("Verify Email", link)}
      ${linkBlock(link)}
      <hr style="border:none;border-top:1px solid #e2e8f0;margin:26px 0;"/>
      <p style="color:#94a3b8;font-size:12.5px;line-height:1.6;">
        If you didn't create an account, you can safely ignore this email.
      </p>`;
  return emailShell("Verify Email", body);
}

function buildPasswordResetHtml(email, link) {
  const body = `
      <p style="color:#334155;font-size:15px;line-height:1.7;margin:0 0 6px;">
        Dear User,
      </p>
      <p style="color:#334155;font-size:15px;line-height:1.7;margin:0 0 6px;">
        A request has been initiated to reset the password for your
        <strong>${APP_NAME}</strong> account associated with
        <strong style="color:#2563eb;">${email}</strong>.
      </p>
      <p style="color:#334155;font-size:15px;line-height:1.7;margin:0 0 6px;">
        Please click the button below to establish a new password for your account:
      </p>
      ${buttonHtml("Click Here", link)}
      ${linkBlock(link)}
      <hr style="border:none;border-top:1px solid #e2e8f0;margin:26px 0;"/>
      <p style="color:#94a3b8;font-size:13px;line-height:1.7;margin:0 0 4px;">
        For safety considerations, this request will automatically expire. If you did not
        authorize this action, please disregard this email. Your current password will remain
        unchanged and secure.
      </p>
      <p style="color:#334155;font-size:15px;line-height:1.7;margin:22px 0 0;">Sincerely,</p>
      <p style="color:#334155;font-size:15px;line-height:1.7;margin:0;">
        The ${APP_NAME} Operations Team
      </p>`;
  return emailShell("Reset Password", body);
}

async function sendResendEmail(to, subject, html) {
  const apiKey = process.env.RESEND_API_KEY;
  if (!apiKey) {
    throw new HttpsError(
      "failed-precondition",
      "Email service is not configured."
    );
  }

  const response = await fetch("https://api.resend.com/emails", {
    method: "POST",
    headers: {
      "Content-Type": "application/json",
      Authorization: `Bearer ${apiKey}`,
    },
    body: JSON.stringify({
      from: "CampusTwin Team <onboarding@resend.dev>",
      to: [to],
      subject,
      html,
    }),
  });

  if (!response.ok) {
    const text = await response.text();
    throw new HttpsError(
      "internal",
      `Email service error (${response.status}): ${text}`
    );
  }
}

exports.sendVerificationEmail = onCall(async (request) => {
  const uid = request.auth?.uid;
  if (!uid) {
    throw new HttpsError(
      "unauthenticated",
      "You must be signed in to request a verification email."
    );
  }

  const user = await admin.auth().getUser(uid);
  if (!user.email) {
    throw new HttpsError("failed-precondition", "User has no email.");
  }

  const link = await admin.auth().generateEmailVerificationLink(user.email);

  await sendResendEmail(
    user.email,
    `Verify your email for ${APP_NAME}`,
    buildVerificationHtml(user.displayName, link)
  );

  logger.info(`Verification email sent to ${user.email}`);
  return {success: true};
});

exports.sendPasswordResetEmail = onCall(async (request) => {
  const email = request.data?.email;
  if (typeof email !== "string" || !email.trim()) {
    throw new HttpsError("invalid-argument", "An email address is required.");
  }

  const link = await admin.auth().generatePasswordResetLink(email.trim());

  await sendResendEmail(
    email.trim(),
    `Reset Your ${APP_NAME} Password`,
    buildPasswordResetHtml(email.trim(), link)
  );

  logger.info(`Password reset email sent to ${email}`);
  return {success: true};
});
