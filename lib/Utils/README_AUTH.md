# Token Authentication Implementation

This document explains the token-based authentication system implemented in the Flutter e-commerce app.

## Overview

The app now uses JWT (JSON Web Token) authentication for all API calls. When a user logs in, they receive a token that is automatically included in the headers of subsequent API requests.

## Key Components

### 1. ApiService (`lib/Utils/ApiService.dart`)

Centralized service for making authenticated API calls.

**Features:**
- Automatic token inclusion in headers
- Token validation before API calls
- Automatic logout on authentication errors
- Support for GET, POST, PUT, DELETE requests

**Usage:**
```dart
// Make an authenticated API call
var response = await ApiService.get('/api/shop/user/6');

// Make an unauthenticated API call (login, registration)
var response = await ApiService.post('/api/auth/login',
body: {'phone': '1234567890', 'password': 'password'},
includeAuth: false
);
```

### 2. AuthMiddleware (`lib/Utils/AuthMiddleware.dart`)

Handles token validation and authentication logic.

**Features:**
- JWT token validation
- Token expiration checking
- Automatic logout on token expiry
- Token information extraction

**Usage:**
```dart
// Check if token is valid
bool isValid = await AuthMiddleware.isTokenValid();

// Get token information
var tokenInfo = await AuthMiddleware.getTokenInfo();
```

### 3. LoginController Updates

The login controller now properly stores the token received from the login response.

**Login Response Format:**
```json
{
  "token": "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9...",
  "user": {
    "id": 6,
    "role": "shopkeeper",
    "username": "Nil"
  }
}
```

## How It Works

### 1. Login Process
1. User enters credentials
2. App sends login request to `/api/auth/login`
3. Server responds with token and user info
4. App stores token in SharedPreferences
5. Token is automatically included in future API calls

### 2. API Call Process
1. App checks if token is valid (not expired)
2. If valid, includes token in Authorization header
3. Makes API request
4. If server returns 401, automatically logs out user

### 3. Token Storage
- **Token**: Stored as `auth_token` in SharedPreferences
- **User ID**: Stored as `user_id` in SharedPreferences
- **User Role**: Stored as `user_role` in SharedPreferences
- **Login Status**: Stored as `is_logged_in` boolean

## Updated Controllers

All controllers have been updated to use the new ApiService:

- **LoginController**: Uses ApiService for login/registration
- **OfferController**: Uses ApiService for offer management
- **ShopController**: Uses ApiService for shop management
- **ActiveOffersController**: Uses ApiService for offer operations
- **NearbyOffersController**: Uses ApiService for location-based offers

## Testing

Use `AuthTestHelper` to test the authentication system:

```dart
// Test the complete authentication flow
await AuthTestHelper.testAuthFlow();

// Test token storage and retrieval
await AuthTestHelper.testTokenStorage();

// Clear test data
await AuthTestHelper.clearTestData();
```

## Security Features

1. **Token Validation**: Every API call validates the token before making the request
2. **Automatic Logout**: Users are automatically logged out if token is invalid or expired
3. **Secure Storage**: Tokens are stored securely in SharedPreferences
4. **Error Handling**: Proper error handling for authentication failures

## API Headers

All authenticated API calls now include:

```http
Authorization: Bearer <jwt_token>
Content-Type: application/json
Accept: application/json
```

## Error Handling

- **401 Unauthorized**: Automatically logs out user and redirects to login
- **Token Expired**: Automatically logs out user and redirects to login
- **Network Errors**: Proper error messages displayed to user

## Migration Notes

- All existing API calls have been updated to use ApiService
- No changes needed in UI components
- Backward compatibility maintained
- Existing SharedPreferences keys preserved

## Example Usage

```dart
// In any controller
class MyController extends GetxController {
  Future<void> fetchData() async {
    try {
      // This will automatically include the token
      var response = await ApiService.get('/api/my-endpoint');

      if (response.statusCode == 200) {
        // Handle success
        var data = jsonDecode(response.body);
        // Process data...
      }
    } catch (e) {
      // Handle error (including auth errors)
      print('Error: $e');
    }
  }
}
```

This implementation ensures secure, token-based authentication across the entire application while maintaining a clean and consistent API interface.
