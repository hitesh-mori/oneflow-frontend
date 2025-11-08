# API Configuration Guide

## Base URL Configuration

To change the backend API URL, update the following file:

**File**: `lib/services/api_service.dart`

```dart
class ApiService {
  static const String baseUrl = 'http://localhost:5000';  // Change this URL

  // Rest of the code...
}
```

## Environment-Specific Configuration

### Development
```dart
static const String baseUrl = 'http://localhost:5000';
```

### Production
```dart
static const String baseUrl = 'https://your-production-api.com';
```

### Staging
```dart
static const String baseUrl = 'https://your-staging-api.com';
```

## API Endpoints Reference

### Authentication Endpoints

#### Sign Up
```
POST /api/auth/signup
Content-Type: application/json

Body:
{
  "name": "string",
  "email": "string",
  "password": "string",
  "phone": "string",
  "userType": "type1" | "type2" | "type3"
}

Response: 201 Created
{
  "success": true,
  "message": "User registered successfully",
  "data": {
    "user": { ... },
    "accessToken": "string",
    "refreshToken": "string"
  }
}
```

#### Sign In
```
POST /api/auth/signin
Content-Type: application/json

Body:
{
  "email": "string",
  "password": "string"
}

Response: 200 OK
{
  "success": true,
  "message": "Login successful",
  "data": {
    "user": { ... },
    "accessToken": "string",
    "refreshToken": "string"
  }
}
```

#### Get Profile
```
GET /api/auth/profile
Authorization: Bearer <accessToken>

Response: 200 OK
{
  "success": true,
  "message": "Profile fetched",
  "data": {
    "_id": "string",
    "name": "string",
    "email": "string",
    "phone": "string",
    "userType": "string",
    "createdAt": "string"
  }
}
```

#### Refresh Token
```
POST /api/auth/refresh
Content-Type: application/json

Body:
{
  "refreshToken": "string"
}

Response: 200 OK
{
  "success": true,
  "message": "Token refreshed",
  "data": {
    "accessToken": "string",
    "refreshToken": "string"
  }
}
```

#### Logout
```
POST /api/auth/logout
Authorization: Bearer <accessToken>

Response: 200 OK
{
  "success": true,
  "message": "Logged out successfully"
}
```

## Error Responses

### 400 Bad Request
```json
{
  "success": false,
  "message": "Validation error message",
  "error": "Error details"
}
```

### 401 Unauthorized
```json
{
  "success": false,
  "message": "Invalid credentials or token expired",
  "error": "Unauthorized"
}
```

### 500 Internal Server Error
```json
{
  "success": false,
  "message": "Server error message",
  "error": "Error details"
}
```

## CORS Configuration

If you encounter CORS issues, ensure your backend has proper CORS configuration:

```javascript
// Backend CORS configuration example
app.use(cors({
  origin: 'http://localhost:port', // Your Flutter web port
  credentials: true
}));
```

## Testing API Endpoints

### Using curl

#### Sign Up
```bash
curl -X POST http://localhost:5000/api/auth/signup \
  -H "Content-Type: application/json" \
  -d '{
    "name": "Test User",
    "email": "test@example.com",
    "password": "password123",
    "phone": "1234567890",
    "userType": "type1"
  }'
```

#### Sign In
```bash
curl -X POST http://localhost:5000/api/auth/signin \
  -H "Content-Type: application/json" \
  -d '{
    "email": "test@example.com",
    "password": "password123"
  }'
```

#### Get Profile
```bash
curl -X GET http://localhost:5000/api/auth/profile \
  -H "Authorization: Bearer YOUR_ACCESS_TOKEN"
```

## Troubleshooting

### Connection Refused
- Ensure backend server is running
- Check the base URL in `api_service.dart`
- Verify firewall settings

### CORS Errors
- Add Flutter web origin to backend CORS configuration
- Enable credentials in CORS settings

### Token Expired
- Token auto-refresh is implemented
- Check refresh token validity
- Clear storage and login again if needed

### Network Errors
- Check internet connection
- Verify backend server is accessible
- Check for proxy/firewall blocking

## Adding New Endpoints

To add a new API endpoint:

1. Add method in `lib/services/auth_service.dart` (or create new service file)
2. Use `ApiService.get/post/put/delete` methods
3. Handle response and errors
4. Update models if needed

Example:
```dart
static Future<UserModel?> updateProfile({
  required String name,
  required String phone,
}) async {
  try {
    final response = await ApiService.put('/api/auth/profile', {
      'name': name,
      'phone': phone,
    }, needsAuth: true);

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      return UserModel.fromJson(data['data']);
    }
    return null;
  } catch (e) {
    return null;
  }
}
```
