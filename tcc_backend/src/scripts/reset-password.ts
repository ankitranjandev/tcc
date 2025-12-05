import db from '../config/database';
import { PasswordUtils } from '../utils/password';
import logger from '../config/logger';

async function resetPassword() {
  try {
    const email = 'a@b.com';
    const newPassword = 'Test@123';

    console.log('\n🔐 Resetting password...');
    console.log(`📧 Email: ${email}`);
    console.log(`🔑 New password: ${newPassword}`);

    // Hash the password
    const passwordHash = await PasswordUtils.hash(newPassword);
    console.log(`✅ Password hashed: ${passwordHash.substring(0, 20)}...`);

    // Update the password
    const result = await db.query(
      `UPDATE users
       SET password_hash = $1,
           failed_login_attempts = 0,
           locked_until = NULL
       WHERE email = $2
       RETURNING email, phone, is_active`,
      [passwordHash, email]
    );

    if (result.length > 0) {
      const user = result[0];
      console.log('\n✅ Password updated successfully!');
      console.log(`📧 Email: ${user.email}`);
      console.log(`📱 Phone: ${user.phone}`);
      console.log(`🔓 Active: ${user.is_active}`);
      console.log(`🔑 Password: ${newPassword}`);
      console.log('\n🎉 You can now login with these credentials!');
    } else {
      console.log(`\n❌ User not found: ${email}`);
    }

    process.exit(0);
  } catch (error) {
    console.error('❌ Error:', error);
    process.exit(1);
  }
}

resetPassword();
