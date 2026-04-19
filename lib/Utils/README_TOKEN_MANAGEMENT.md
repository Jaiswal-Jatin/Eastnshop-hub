# Token Management System with Automatic Refresh

This document explains the enhanced token-based authentication system with automatic token refresh functionality implemented in the Flutter e-commerce app.

## Overview

The app now includes a robust token management system that automatically handles token refresh when tokens expire, ensuring seamless user experience without requiring manual re-authentication.

## Key Components

### 1. TokenManager (`lib/Utils/TokenManager.dart`)

Centralized service for managing authentication tokens with automatic refresh capabilities.

**Key Features:**
- Automatic token storage and retrieval
- Token expiry detection and validation
- Automatic token refresh using refresh tokens
- Secure token management with SharedPreferences
- JWT token decoding and validation

**Main Methods:**
```dart
// Store tokens after login
await TokenManager.storeTokens(
accessToken: 'your_access_token',
refreshToken: 'your_refresh_token',
expiresIn: 3600, // Token expiry in seconds
);

// Get valid access token (automatically refresh if needed)
String? token = await TokenManager.getValidAccessToken();

// Check if token is expired or expiring soon
bool isExpired = await TokenManager.isTokenExpiredOrExpiringSoon();

// Refresh access token manually
bool success = await TokenManager.refreshAccessToken();

// Check authentication status
bool isAuthenticated = await TokenManager.isAuthenticated();

// Clear all tokens
await TokenManager.clearTokens();
```

### 2. Enhanced ApiService (`lib/Utils/ApiService.dart`)

Updated to use TokenManager for automatic token management.

**Key Changes:**
- Automatic token refresh before API calls
- Seamless token handling in headers
- Enhanced error handling for authentication failures
- Automatic retry logic for expired tokens

**Usage:**
```dart
// All API calls now automatically handle token refresh
var response = await ApiService.get('/api/shop/user/6');
var response = await ApiService.post('/api/data', body: {'key': 'value'});
```

### 3. Updated LoginController (`lib/Controllers/LoginController.dart`)

Modified to use TokenManager for storing tokens after successful login.

**Key Changes:**
- Uses `TokenManager.storeTokens()` instead of direct SharedPreferences
- Handles refresh tokens from login response
- Stores token expiry information

### 4. Enhanced AuthMiddleware (`lib/Utils/AuthMiddleware.dart`)

Simplified to use TokenManager for all token operations.

**Key Changes:**
- Delegates token validation to TokenManager
- Uses TokenManager for token information retrieval
- Simplified authentication error handling

## How It Works

### 1. Login Process
1. User enters credentials
2. App sends login request to `/api/auth/login`
3. Server responds with access token, refresh token, and expiry information
4. `TokenManager.storeTokens()` stores all token data securely
5. User data is stored in SharedPreferences

### 2. Automatic Token Refresh
1. Before each API call, `TokenManager.getValidAccessToken()` is called
2. If token is expired or expiring soon (within 5 minutes), automatic refresh is triggered
3. Refresh token is sent to `/api/auth/refresh-token` endpoint
4. New tokens are received and stored automatically
5. API call proceeds with the new access token

### 3. Token Expiry Handling
- Tokens are considered expired if they expire within 5 minutes
- JWT tokens are decoded to check expiration time
- Fallback to stored expiry time if JWT decoding fails
- Automatic refresh is attempted before API calls

### 4. Error Handling
- If token refresh fails, user is redirected to login
- All authentication data is cleared on refresh failure
- 401 responses trigger automatic token refresh attempt
- Failed refresh results in logout and login redirect

## API Endpoints

### Login Endpoint
```
POST /api/auth/login
Body: {
  "phone": "1234567890",
  "password": "password"
}
Response: {
  "token": "access_token",
  "refresh_token": "refresh_token",
  "expires_in": 3600,
  "user": {
    "id": 6,
    "role": "shopkeeper",
    "username": "user"
  }
}
```

### Token Refresh Endpoint
```
POST /api/auth/refresh-token
Body: {
  "refresh_token": "refresh_token"
}
Response: {
  "token": "new_access_token",
  "refresh_token": "new_refresh_token",
  "expires_in": 3600
}
```

## Token Storage

### SharedPreferences Keys
- `auth_token`: Access token
- `refresh_token`: Refresh token
- `token_expiry`: Token expiry timestamp
- `is_logged_in`: Authentication status
- `user_id`: User ID
- `user_role`: User role
- `username`: Username
- `user_email`: User email
- `user_phone`: User phone

## Testing

### TokenRefreshTestHelper (`lib/Utils/TokenRefreshTestHelper.dart`)

Comprehensive testing utility for the token management system.

**Test Methods:**
```dart
// Test complete token refresh flow
await TokenRefreshTestHelper.testTokenRefreshFlow();

// Test token expiry scenarios
await TokenRefreshTestHelper.testTokenExpiryScenarios();

// Demonstrate complete authentication flow
await TokenRefreshTestHelper.demonstrateCompleteFlow();

// Clear test data
await TokenRefreshTestHelper.clearTestData();
```

## Benefits

1. **Seamless User Experience**: Users don't need to manually re-authenticate when tokens expire
2. **Automatic Token Management**: All token operations are handled automatically
3. **Secure Token Storage**: Tokens are stored securely using SharedPreferences
4. **Robust Error Handling**: Comprehensive error handling for various failure scenarios
5. **Easy Integration**: Simple API for all token operations
6. **Comprehensive Logging**: Detailed logging for debugging and monitoring

## Security Considerations

1. **Token Storage**: Tokens are stored securely in SharedPreferences
2. **Automatic Cleanup**: All tokens are cleared on logout or authentication failure
3. **Expiry Validation**: Multiple layers of token expiry validation
4. **Error Handling**: Secure error handling prevents token leakage
5. **Refresh Token Security**: Refresh tokens are handled securely

## Migration Notes

### For Existing Code
- No changes required for existing API calls
- Token management is handled automatically
- Existing authentication checks continue to work
- Enhanced error handling provides better user experience

### For New Features
- Use `TokenManager` for all token operations
- Leverage automatic token refresh for API calls
- Implement proper error handling for authentication failures

## Troubleshooting

### Common Issues
1. **Token Refresh Fails**: Check refresh token endpoint and network connectivity
2. **Authentication Errors**: Verify token storage and expiry handling
3. **API Call Failures**: Ensure proper error handling and retry logic

### Debugging
- Use `TokenManager.getTokenInfo()` for token debugging
- Check logs for detailed authentication flow information
- Use `TokenRefreshTestHelper` for testing token scenarios

## Future Enhancements

1. **Token Rotation**: Implement token rotation for enhanced security
2. **Biometric Authentication**: Add biometric authentication support
3. **Multi-Device Support**: Handle tokens across multiple devices
4. **Offline Support**: Cache tokens for offline usage
5. **Analytics**: Add authentication analytics and monitoring
