# Consumers Section - Quick Reference Guide

## What is the Consumers Section?

The Consumers section is a dedicated management interface for all users who register and use the **TCC User Mobile Client App**. These are the end-users who:
- Download and use the TCC mobile app
- Create accounts to manage their finances
- Make investments
- Pay bills
- Use digital wallets
- Participate in voting

## Key Difference: Consumers vs Users vs Agents

| Section | Purpose | User Type |
|---------|---------|-----------|
| **Consumers** | Mobile app end-users | Regular consumers (role: USER) |
| **Users** | All system users | Various user types |
| **Agents** | Field agents | Agents who serve consumers |

## Accessing the Consumers Section

1. Login to the admin dashboard at: `http://localhost:PORT`
2. Look at the left sidebar navigation
3. Click on "Consumers" (located between "Users" and "Agents")
4. The Consumers management page will load

## Main Features

### 1. Statistics Dashboard
At the top of the page, you'll see four key metrics:
- **Total Consumers**: Total number of registered consumers
- **Active Consumers**: Currently active consumer accounts
- **Pending KYC**: Consumers waiting for KYC verification
- **Total Investments**: Sum of all consumer investments

### 2. Search & Filters

#### Search Box
- Type consumer name, email, or phone number
- Results update in real-time
- Case-insensitive search

#### Status Filter
Options:
- **All**: Show all consumers
- **Active**: Only active accounts
- **Inactive**: Dormant accounts
- **Suspended**: Suspended accounts

#### KYC Status Filter
Options:
- **All**: Show all KYC statuses
- **Pending**: KYC not yet submitted or under review
- **Approved**: KYC verified and approved
- **Rejected**: KYC application rejected
- **Under Review**: KYC documents being reviewed

### 3. Consumer List

The consumer list displays:
- **Consumer ID**: Unique identifier (truncated)
- **Name**: Full name with avatar initial
- **Email**: Contact email address
- **Phone**: Contact phone number
- **KYC Status**: Color-coded badge
- **Account Status**: Active/Inactive/Suspended
- **Wallet Balance**: Current wallet balance in SLL
- **Transactions**: Total number of transactions
- **Registered**: Account creation date

### 4. Actions

For each consumer, you can:

#### View Details (Eye Icon)
Opens a detailed dialog showing:
- Complete profile information
- Contact details
- Financial information
- Account status and KYC status
- Registration and activity dates
- Bank details status
- Investment status

#### Activate/Suspend (Check/Block Icon)
- **Active Consumer**: Click to suspend the account
- **Inactive/Suspended Consumer**: Click to activate the account
- Confirmation dialog will appear before action is executed

## How to Use

### Viewing Consumer Details
1. Find the consumer in the list (use search if needed)
2. Click the **eye icon** in the Actions column
3. Review all consumer information in the dialog
4. Click **Close** when done

### Activating a Consumer
1. Find the suspended/inactive consumer
2. Click the **check circle icon** (green)
3. Confirm the action in the dialog
4. Consumer account will be activated
5. Success message will appear

### Suspending a Consumer
1. Find the active consumer
2. Click the **block icon** (red)
3. Confirm the action in the dialog
4. Consumer account will be suspended
5. Success message will appear

### Searching for Consumers
1. Type in the search box at the top
2. Results filter automatically
3. You can search by:
   - First name
   - Last name
   - Email address
   - Phone number

### Filtering by Status
1. Click the **Status Filter** dropdown
2. Select desired status:
   - All
   - Active
   - Inactive
   - Suspended
3. List updates automatically

### Filtering by KYC Status
1. Click the **KYC Status Filter** dropdown
2. Select desired KYC status:
   - All
   - Pending
   - Approved
   - Rejected
   - Under Review
3. List updates automatically

### Exporting Consumer Data
1. Click the **Export** button
2. Data will be downloaded (feature coming soon)

### Navigating Pages
If you have more than 25 consumers:
1. Current page number is highlighted
2. Click **Previous** to go back
3. Click **Next** to go forward
4. Page indicator shows: "Showing X-Y of Z consumers"

## Responsive Design

### Desktop View
- Full data table with all columns
- Horizontal scrolling if needed
- Side-by-side filters

### Tablet/Mobile View
- Card-based layout
- Stacked filters
- Vertical scrolling
- Touch-friendly buttons

## Status Badges

### Account Status
- 🟢 **Active**: Green badge - Account is operational
- ⚪ **Inactive**: Gray badge - Account is dormant
- 🔴 **Suspended**: Red badge - Account is suspended

### KYC Status
- 🟡 **Pending**: Yellow badge - Awaiting submission/review
- 🟢 **Approved**: Green badge - KYC verified
- 🔴 **Rejected**: Red badge - KYC rejected
- 🔵 **Under Review**: Blue badge - Being reviewed

## Common Workflows

### 1. Review New Consumers
```
1. Filter by KYC Status: "Pending"
2. Review each consumer's details
3. Check KYC documents (via detail view)
4. Update KYC status accordingly
```

### 2. Monitor Active Consumers
```
1. Filter by Status: "Active"
2. Sort by recent activity
3. Review wallet balances
4. Check transaction counts
```

### 3. Investigate Suspended Accounts
```
1. Filter by Status: "Suspended"
2. Review suspension reasons
3. Check activity logs
4. Decide on reactivation
```

### 4. Find Specific Consumer
```
1. Use search box
2. Type name, email, or phone
3. View details
4. Take necessary action
```

## Troubleshooting

### No Consumers Showing
- Check if backend API is running
- Verify database has consumer records
- Check console for errors
- Try refreshing the page

### Search Not Working
- Ensure you're typing at least 3 characters
- Check internet connection
- Verify API endpoint is accessible

### Actions Not Working
- Confirm you have admin permissions
- Check if backend is responding
- Look for error messages in snackbar
- Verify API authentication token

### Filters Not Applying
- Try clearing filters and reapplying
- Refresh the page
- Check if any console errors appear

## API Endpoints Used

Backend endpoints for consumer management:
- `GET /admin/users?role=USER` - List consumers
- `GET /admin/users/:id` - Get consumer details
- `PUT /admin/users/:id/status` - Update status
- `GET /admin/users/stats?role=USER` - Statistics

## Tips

1. **Use Filters Efficiently**: Combine search with filters for precise results
2. **Regular Monitoring**: Check pending KYC regularly
3. **Status Management**: Keep accounts updated (active/inactive)
4. **Bulk Actions**: Use export for offline analysis
5. **Mobile Testing**: Test responsive design on different devices

## Future Enhancements (Coming Soon)

- CSV export functionality
- Bulk consumer operations
- Consumer edit capability
- Advanced filtering options
- Transaction history view
- Investment portfolio view
- KYC document review interface
- Activity log viewer
- Email notifications
- Bulk status updates

## Need Help?

If you encounter issues:
1. Check browser console for errors
2. Verify backend API is running
3. Ensure proper authentication
4. Review API documentation
5. Contact development team

---

**Version**: 1.0
**Last Updated**: December 2025
**Component**: TCC Admin Dashboard - Consumers Section
