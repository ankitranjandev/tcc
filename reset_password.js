const bcrypt = require('bcrypt');
const { Client } = require('pg');

// Database configuration
const client = new Client({
  host: 'localhost',
  port: 5432,
  database: 'tcc_database',
  user: 'shubham',
  password: '',
});

async function resetPassword() {
  try {
    await client.connect();
    console.log('Connected to database');

    // Email and new password
    const email = 'a@b.com';
    const newPassword = 'Test@123';

    // Hash the password
    const salt = await bcrypt.genSalt(10);
    const passwordHash = await bcrypt.hash(newPassword, salt);

    console.log(`\nResetting password for: ${email}`);
    console.log(`New password: ${newPassword}`);
    console.log(`Password hash: ${passwordHash.substring(0, 20)}...`);

    // Update the password
    const result = await client.query(
      'UPDATE users SET password_hash = $1, failed_login_attempts = 0, locked_until = NULL WHERE email = $2 RETURNING email',
      [passwordHash, email]
    );

    if (result.rows.length > 0) {
      console.log(`\n✅ Password updated successfully for ${email}`);
      console.log(`📧 Email: ${email}`);
      console.log(`🔑 Password: ${newPassword}`);
      console.log(`\nYou can now login with these credentials!`);
    } else {
      console.log(`\n❌ User not found: ${email}`);
    }

  } catch (error) {
    console.error('Error:', error.message);
  } finally {
    await client.end();
  }
}

resetPassword();
