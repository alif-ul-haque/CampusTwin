const {setGlobalOptions} = require("firebase-functions");
const {onCall, HttpsError} = require("firebase-functions/v2/https");
const logger = require("firebase-functions/logger");
const admin = require("firebase-admin");
const nodemailer = require("nodemailer");

admin.initializeApp();
setGlobalOptions({maxInstances: 10});

const APP_NAME = "CampusTwin";

function buildVerificationHtml(displayName, link) {
  return `
<!DOCTYPE html>
<html>
<body style="margin:0;padding:0;background:#f1f5f9;font-family:Segoe UI,Arial,sans-serif;">
  <div style="max-width:520px;margin:40px auto;background:#ffffff;border-radius:16px;overflow:hidden;box-shadow:0 4px 12px rgba(0,0,0,0.08);">
    <div style="background:#2563eb;padding:28px;text-align:center;">
      <h1 style="color:#ffffff;margin:0;font-size:24px;">${APP_NAME}</h1>
    </div>
    <div style="padding:32px;">
      <h2 style="color:#0f172a;margin-top:0;">Hi ${displayName || "there"},</h2>
      <p style="color:#334155;font-size:15px;line-height:1.6;">
        Welcome to ${APP_NAME}! Please confirm your email address so we know it's really you.
      </p>
      <div style="text-align:center;margin:28px 0;">
        <a href="${link}"
           style="background:#2563eb;color:#ffffff;text-decoration:none;
                  padding:14px 36px;border-radius:10px;font-weight:bold;display:inline-block;">
          Verify Email
        </a>
      </div>
      <p style="color:#64748b;font-size:13px;line-height:1.6;">
        Or copy this link into your browser:<br/>
        <a href="${link}" style="color:#2563eb;word-break:break-all;">${link}</a>
      </p>
      <hr style="border:none;border-top:1px solid #e2e8f0;margin:24px 0;"/>
      <p style="color:#94a3b8;font-size:12px;">
        If you didn't create an account, you can safely ignore this email.
      </p>
    </div>
    <div style="background:#f8fafc;padding:16px;text-align:center;">
      <p style="color:#94a3b8;font-size:12px;margin:0;">&copy; ${new Date().getFullYear()} ${APP_NAME} Team</p>
    </div>
  </div>
</body>
</html>`;
}

exports.sendVerificationEmail = onCall(async (request) => {
  const uid = request.auth?.uid;
  if (!uid) {
    throw new functions.https.HttpsError(
      "unauthenticated",
      "You must be signed in to request a verification email."
    );
  }

  const user = await admin.auth().getUser(uid);
  if (!user.email) {
    throw new HttpsError("failed-precondition", "User has no email.");
  }

  const link = await admin.auth().generateEmailVerificationLink(user.email);

  const transporter = nodemailer.createTransport({
    service: "gmail",
    auth: {
      user: process.env.GMAIL_USER,
      pass: process.env.GMAIL_APP_PASSWORD,
    },
  });

  await transporter.sendMail({
    from: `"CampusTwin Team" <${process.env.GMAIL_USER}>`,
    to: user.email,
    subject: `Verify your email for ${APP_NAME}`,
    html: buildVerificationHtml(user.displayName, link),
  });

  logger.info(`Verification email sent to ${user.email}`);
  return {success: true};
});
