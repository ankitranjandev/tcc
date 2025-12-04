# Admin Dashboard Setup Guide

## Issue: 403 Forbidden Error on Dashboard

### Problem Description
The admin dashboard was showing a **403 Forbidden error** when trying to access `/admin/dashboard/stats` endpoint after successful login.

### Root Cause
The 403 error occurs because:
1. The backend requires users to have `ADMIN` or `SUPER_ADMIN` role to access admin endpoints
2. No admin users exist in the database by default
3. The database schema supports admin roles, but no admin user was seeded

### Solution

#### Step 1: Create an Admin User

Run the provided SQL script to create a default super admin user:

```bash
cd /Users/shubham/Documents/playground/tcc/tcc_backend
psql -U postgres -d tcc_db -f seed_admin_user.sql
```

Or if using a different database connection:

```bash
psql postgresql://username:password@localhost:5432/tcc_db -f seed_admin_user.sql
```

#### Step 2: Default Admin Credentials

After running the seed script, you can login with:

- **Email:** `admin@tcc.sl`
- **Password:** `Admin@123456`

**⚠️ IMPORTANT:** Change this password immediately after first login!

#### Step 3: Verify Admin User Creation

You can verify the admin user was created by running:

```sql
SELECT id, role, first_name, last_name, email, is_active
FROM users
WHERE role IN ('ADMIN', 'SUPER_ADMIN');
```

#### Step 4: Login to Admin Panel

1. Navigate to the admin panel login page
2. Enter the email: `admin@tcc.sl`
3. Enter the password: `Admin@123456`
4. You should now be able to access the dashboard

## Dashboard Features

The admin dashboard now includes:

### 1. **Key Performance Indicators (KPIs)**
- Total Users
- Active Agents
- Total Transactions
- Total Revenue

### 2. **Today's Performance**
- Today's transaction count
- Today's revenue

### 3. **Quick Actions**
- Pending KYC approvals
- Pending withdrawals

### 4. **Real-time Updates**
- Pull-to-refresh capability
- Manual refresh button
- Auto-loading on mount

### 5. **Error Handling**
- Loading states with spinner
- Error messages with retry functionality
- User-friendly error displays

## API Endpoints Used

The dashboard fetches data from:

```
GET /admin/dashboard/stats
```

Returns:
```json
{
  "success": true,
  "data": {
    "totalUsers": number,
    "totalTransactions": number,
    "totalRevenue": number,
    "activeAgents": number,
    "pendingWithdrawals": number,
    "pendingKYC": number,
    "todayRevenue": number,
    "todayTransactions": number
  }
}
```

## Authentication Flow

1. **Login:** User logs in with email/password
2. **Token Generation:** Backend generates JWT access token with user role
3. **Token Storage:** Flutter app stores token in secure storage
4. **API Requests:** All API requests include `Authorization: Bearer <token>` header
5. **Authorization:** Backend validates token and checks user role
6. **Access Granted:** If user has ADMIN or SUPER_ADMIN role, access is granted

## Files Modified

### Backend
- No changes needed to backend code
- Created: `tcc_backend/seed_admin_user.sql` - Seeds default admin user

### Frontend (Admin Client)
1. **`lib/screens/dashboard/dashboard_screen.dart`**
   - Converted from StatelessWidget to StatefulWidget
   - Added API integration with DashboardService
   - Removed MockDataService dependency
   - Added loading, error, and success states
   - Added pull-to-refresh and manual refresh
   - Added today's performance section

2. **`lib/screens/transactions/transactions_screen.dart`**
   - Already updated to fetch from API (by linter)
   - Uses TransactionService for real data

3. **Auth Service**
   - Already properly configured
   - Saves tokens after successful login
   - Adds Authorization header to all requests

## Testing the Dashboard

1. **Start the Backend:**
   ```bash
   cd /Users/shubham/Documents/playground/tcc/tcc_backend
   npm run dev
   ```

2. **Seed Admin User:**
   ```bash
   psql postgresql://localhost:5432/tcc_db -f seed_admin_user.sql
   ```

3. **Start the Admin Client:**
   ```bash
   cd /Users/shubham/Documents/playground/tcc/tcc_admin_client
   flutter run -d chrome
   ```

4. **Login:**
   - Email: `admin@tcc.sl`
   - Password: `Admin@123456`

5. **View Dashboard:**
   - Dashboard should load with real data
   - Pull down to refresh
   - Click refresh icon to manually refresh

## Creating Additional Admin Users

To create additional admin users manually:

```sql
INSERT INTO users (
    role,
    first_name,
    last_name,
    email,
    phone,
    password_hash,
    kyc_status,
    is_active,
    is_verified,
    email_verified,
    phone_verified
) VALUES (
    'ADMIN',  -- or 'SUPER_ADMIN'
    'John',
    'Doe',
    'john.doe@tcc.sl',
    '+23276123456',
    '$2b$12$your_bcrypt_hash_here',
    'APPROVED',
    true,
    true,
    true,
    true
);
```

To generate a password hash, you can use the backend's password utility or online bcrypt generators.

## Troubleshooting

### Issue: Still getting 403 error

**Solution:**
1. Clear browser cache and local storage
2. Logout and login again
3. Check if admin user exists: `SELECT * FROM users WHERE role IN ('ADMIN', 'SUPER_ADMIN')`
4. Verify token is being sent: Check browser DevTools → Network → Headers

### Issue: No data showing

**Solution:**
1. Check backend is running: `http://localhost:3000/health`
2. Check database has data
3. Check browser console for errors
4. Try manual refresh

### Issue: Login failed

**Solution:**
1. Verify email and password are correct
2. Check user is active: `SELECT is_active FROM users WHERE email = 'admin@tcc.sl'`
3. Check account is not locked: `SELECT locked_until FROM users WHERE email = 'admin@tcc.sl'`
4. Reset password if needed

## Security Notes

1. **Change Default Password:** The default password `Admin@123456` should be changed immediately
2. **Enable 2FA:** Consider enabling two-factor authentication for admin accounts
3. **Use Strong Passwords:** Enforce strong password policies
4. **Regular Audits:** Monitor admin access logs
5. **Principle of Least Privilege:** Only grant SUPER_ADMIN role when necessary

## Next Steps

1. ✅ Dashboard loads real data from API
2. ✅ Transactions screen loads real data from API
3. ⏳ Implement users management screen with API
4. ⏳ Implement agents management screen with API
5. ⏳ Implement KYC approval workflow
6. ⏳ Implement withdrawal approval workflow
7. ⏳ Add recent activity API endpoint
8. ⏳ Add growth metrics calculations
