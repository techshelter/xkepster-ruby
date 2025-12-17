# Xkepster Client API Specification

Version: 1.2.0  
Last Updated: December 17, 2025

## Table of Contents

1. [Overview](#overview)
2. [Authentication](#authentication)
3. [Base URLs & Headers](#base-urls--headers)
4. [Error Handling](#error-handling)
5. [Data Formats](#data-formats)
6. [API Endpoints](#api-endpoints)
   - [Users](#users)
   - [Groups](#groups)
   - [SMS Authentication](#sms-authentication)
   - [Email Authentication](#email-authentication)
   - [Tokens](#tokens)
   - [Machine Tokens](#machine-tokens)
   - [Sessions](#sessions)
   - [Operation Tokens](#operation-tokens)
   - [Audit Logs](#audit-logs)
   - [Realm](#realm)
7. [Security Features](#security-features)
8. [Webhooks](#webhooks)
9. [Rate Limiting](#rate-limiting)
10. [Client Implementation Guide](#client-implementation-guide)

---

## Overview

Xkepster is a multi-tenant identity and access management platform built with Elixir/Phoenix using the Ash Framework. It provides comprehensive user authentication, session management, and audit logging through a JSON:API compliant REST API.

### Key Features

- Multi-tenant architecture with PostgreSQL schema-based isolation
- SMS and Email-based authentication with OTP/Magic Links
- JWT token management with rotation and family tracking
- Session tracking and management
- Operation tokens for sensitive actions
- Comprehensive audit logging
- Role-based access control (User, Admin)
- Group-based organization
- Webhook-based delivery for OTP/Magic Links
- Replay attack prevention (optional)

---

## Authentication

### Realm API Key

All API requests must include a realm-specific API key in the request headers.

**Header:**
```
X-Kepster-Key: <your-realm-api-key>
```

The API key identifies the tenant/realm and automatically scopes all operations to that realm's data.

### User Bearer Token

For user-authenticated endpoints, include a JWT bearer token:

**Header:**
```
Authorization: Bearer <jwt-token>
```

Bearer tokens are obtained through the authentication flow (SMS/Email verification).

### Machine Token

For automated systems and CI/CD pipelines, use machine tokens for long-lived authentication:

**Header:**
```
X-Machine-Token: <machine-token>
```

Machine tokens:
- Are long-lived (30-365 days)
- Can be used multiple times
- Are created via the admin dashboard
- Automatically authenticate as an admin user
- Track last usage timestamp
- Can be manually revoked

**Note:** Machine tokens are only created through the admin dashboard, not via the API.

### Authorization Levels

- **Public**: No authentication required
- **User**: Requires bearer token
- **Admin**: Requires bearer token with admin role OR machine token
- **Machine**: Requires machine token (for CI/CD and automation)

---

## Base URLs & Headers

### Base URL

```
https://your-xkepster-instance.com/api/json
```

### Required Headers

```http
Content-Type: application/vnd.api+json
Accept: application/vnd.api+json
X-Kepster-Key: <realm-api-key>
```

### Optional Security Headers

For realms with enhanced security enabled:

```http
X-Request-Timestamp: <ISO8601-timestamp>
X-Request-Signature: <HMAC-SHA256-signature>
X-Idempotency-Key: <unique-request-id>
```

---

## Error Handling

### Error Response Format

All errors follow JSON:API error object specification:

```json
{
  "errors": [
    {
      "status": "400",
      "title": "Bad Request",
      "detail": "Missing required field: first_name",
      "source": {
        "pointer": "/data/attributes/first_name"
      }
    }
  ]
}
```

### HTTP Status Codes

- `200 OK` - Successful request
- `201 Created` - Resource created successfully
- `204 No Content` - Successful deletion
- `400 Bad Request` - Invalid request data
- `401 Unauthorized` - Missing or invalid API key/token
- `403 Forbidden` - Insufficient permissions
- `404 Not Found` - Resource not found
- `422 Unprocessable Entity` - Validation error
- `429 Too Many Requests` - Rate limit exceeded
- `500 Internal Server Error` - Server error

---

## Data Formats

### Dates & Times

All timestamps are in ISO 8601 format (UTC):
```
2025-11-19T14:30:00Z
```

### UUIDs

All resource IDs are UUID v4:
```
123e4567-e89b-12d3-a456-426614174000
```

### JSON:API Format

All requests and responses follow JSON:API v1.0 specification:

**Request:**
```json
{
  "data": {
    "type": "users",
    "attributes": {
      "first_name": "John",
      "last_name": "Doe"
    }
  }
}
```

**Response:**
```json
{
  "data": {
    "type": "users",
    "id": "123e4567-e89b-12d3-a456-426614174000",
    "attributes": {
      "first_name": "John",
      "last_name": "Doe",
      "role": "user",
      "inserted_at": "2025-11-19T14:30:00Z",
      "updated_at": "2025-11-19T14:30:00Z"
    }
  }
}
```

---

## API Endpoints

### Users

#### Create User

Creates a new user in the current realm.

**Endpoint:** `POST /users`  
**Auth:** Admin  
**Content-Type:** `application/vnd.api+json`

**Request Body:**
```json
{
  "data": {
    "type": "users",
    "attributes": {
      "first_name": "John",
      "last_name": "Doe",
      "role": "user",
      "custom_fields": {
        "department": "Engineering",
        "employee_id": "EMP001"
      }
    },
    "relationships": {
      "groups": {
        "data": [
          { "type": "groups", "id": "group-uuid-1" },
          { "type": "groups", "id": "group-uuid-2" }
        ]
      }
    }
  }
}
```

**Response:** `201 Created`
```json
{
  "data": {
    "type": "users",
    "id": "user-uuid",
    "attributes": {
      "first_name": "John",
      "last_name": "Doe",
      "role": "user",
      "locked": false,
      "locked_at": null,
      "locked_reason": null,
      "custom_fields": {
        "department": "Engineering",
        "employee_id": "EMP001"
      },
      "inserted_at": "2025-11-19T14:30:00Z",
      "updated_at": "2025-11-19T14:30:00Z"
    },
    "relationships": {
      "groups": {
        "data": [
          { "type": "groups", "id": "group-uuid-1" },
          { "type": "groups", "id": "group-uuid-2" }
        ]
      }
    }
  }
}
```

**Fields:**
- `first_name` (string, required): User's first name
- `last_name` (string, optional): User's last name
- `role` (enum, optional): User role - `"user"` (default) or `"admin"`
- `custom_fields` (object, optional): Custom JSON data for the user

#### List Users

Retrieve all users in the current realm.

**Endpoint:** `GET /users`  
**Auth:** Admin or User (users can only see themselves)

**Query Parameters:**
- `page[limit]` (integer): Number of results per page (default: 25)
- `page[offset]` (integer): Offset for pagination
- `filter[role]` (string): Filter by role (`user` or `admin`)
- `filter[locked]` (boolean): Filter by locked status
- `sort` (string): Sort field (e.g., `first_name`, `-inserted_at` for descending)
- `include` (string): Include relationships (e.g., `groups`, `sessions`)

**Example Request:**
```http
GET /users?page[limit]=10&filter[role]=user&sort=-inserted_at&include=groups
```

**Response:** `200 OK`
```json
{
  "data": [
    {
      "type": "users",
      "id": "user-uuid",
      "attributes": {
        "first_name": "John",
        "last_name": "Doe",
        "role": "user",
        "locked": false,
        "custom_fields": {},
        "inserted_at": "2025-11-19T14:30:00Z",
        "updated_at": "2025-11-19T14:30:00Z"
      }
    }
  ],
  "links": {
    "self": "/users?page[limit]=10",
    "next": "/users?page[limit]=10&page[offset]=10"
  },
  "meta": {
    "total_count": 42
  }
}
```

#### Get User

Retrieve a specific user by ID.

**Endpoint:** `GET /users/:id`  
**Auth:** Admin or User (own profile only)

**Response:** `200 OK`
```json
{
  "data": {
    "type": "users",
    "id": "user-uuid",
    "attributes": {
      "first_name": "John",
      "last_name": "Doe",
      "role": "user",
      "locked": false,
      "locked_at": null,
      "locked_reason": null,
      "custom_fields": {},
      "inserted_at": "2025-11-19T14:30:00Z",
      "updated_at": "2025-11-19T14:30:00Z"
    }
  }
}
```

#### Update User

Update user information.

**Endpoint:** `PATCH /users/:id`  
**Auth:** Admin or User (own profile only)

**Request Body:**
```json
{
  "data": {
    "type": "users",
    "id": "user-uuid",
    "attributes": {
      "first_name": "Jane",
      "custom_fields": {
        "phone": "+1234567890"
      }
    }
  }
}
```

**Updatable Fields (User):**
- `first_name` (string)
- `last_name` (string)
- `custom_fields` (object)

**Updatable Fields (Admin):**
- Same as user, plus can update other users

**Response:** `200 OK` (returns updated user)

#### Lock User

Lock a user account (Admin only).

**Endpoint:** `PATCH /users/:id`  
**Auth:** Admin  
**Action:** `lock`

**Request Body:**
```json
{
  "data": {
    "type": "users",
    "id": "user-uuid",
    "attributes": {
      "locked": true,
      "locked_reason": "Security violation"
    }
  }
}
```

**Fields:**
- `locked_reason` (string, required): Reason for locking the account

**Response:** `200 OK`

#### Unlock User

Unlock a locked user account (Admin only).

**Endpoint:** `PATCH /users/:id`  
**Auth:** Admin  
**Action:** `unlock`

**Request Body:**
```json
{
  "data": {
    "type": "users",
    "id": "user-uuid",
    "attributes": {
      "locked": false
    }
  }
}
```

**Response:** `200 OK`

#### Promote User to Admin

Promote a user to admin role.

**Endpoint:** `PATCH /users/:id`  
**Auth:** Admin  
**Action:** `promote_to_admin`

**Request Body:**
```json
{
  "data": {
    "type": "users",
    "id": "user-uuid",
    "attributes": {
      "role": "admin"
    }
  }
}
```

**Response:** `200 OK`

#### Delete User

Delete a user account.

**Endpoint:** `DELETE /users/:id`  
**Auth:** Admin

**Response:** `204 No Content`

---

### Groups

Groups organize users and define authentication strategies (SMS, Email, or both).

#### Create Group

**Endpoint:** `POST /groups`  
**Auth:** Admin

**Request Body:**
```json
{
  "data": {
    "type": "groups",
    "attributes": {
      "name": "Engineering Team",
      "description": "Engineering department members",
      "auth_strategy": "both",
      "allow_registration": true
    }
  }
}
```

**Fields:**
- `name` (string, required): Unique group name
- `description` (string, optional): Group description
- `auth_strategy` (enum, optional): `"sms"`, `"email"`, or `"both"` (default: `"both"`)
- `allow_registration` (boolean, optional): Allow self-registration (default: `false`)

**Response:** `201 Created`
```json
{
  "data": {
    "type": "groups",
    "id": "group-uuid",
    "attributes": {
      "name": "Engineering Team",
      "description": "Engineering department members",
      "auth_strategy": "both",
      "allow_registration": true,
      "inserted_at": "2025-11-19T14:30:00Z",
      "updated_at": "2025-11-19T14:30:00Z"
    }
  }
}
```

#### List Groups

**Endpoint:** `GET /groups`  
**Auth:** User (authenticated)

**Query Parameters:**
- `page[limit]` (integer): Number of results per page
- `page[offset]` (integer): Offset for pagination
- `filter[allow_registration]` (boolean): Filter by registration status
- `filter[auth_strategy]` (string): Filter by auth strategy

**Response:** `200 OK`
```json
{
  "data": [
    {
      "type": "groups",
      "id": "group-uuid",
      "attributes": {
        "name": "Engineering Team",
        "description": "Engineering department members",
        "auth_strategy": "both",
        "allow_registration": true,
        "inserted_at": "2025-11-19T14:30:00Z",
        "updated_at": "2025-11-19T14:30:00Z"
      }
    }
  ]
}
```

#### Get Group

**Endpoint:** `GET /groups/:id`  
**Auth:** User

**Response:** `200 OK`

#### Update Group

**Endpoint:** `PATCH /groups/:id`  
**Auth:** Admin

**Request Body:**
```json
{
  "data": {
    "type": "groups",
    "id": "group-uuid",
    "attributes": {
      "description": "Updated description",
      "allow_registration": false
    }
  }
}
```

**Response:** `200 OK`

#### Delete Group

**Endpoint:** `DELETE /groups/:id`  
**Auth:** Admin

**Response:** `204 No Content`

#### List Groups Accepting Registration

Get groups that allow self-registration.

**Endpoint:** `GET /groups?filter[allow_registration]=true`  
**Auth:** Public

**Response:** `200 OK`

---

### SMS Authentication

SMS-based authentication using OTP (One-Time Password) codes.

#### Register with SMS

Start SMS registration process. Sends OTP to the provided phone number via webhook.

**Endpoint:** `POST /sms_auths`  
**Auth:** Public (requires group_id for group that allows registration)  
**Action:** `register`

**Request Body:**
```json
{
  "data": {
    "type": "sms_auths",
    "attributes": {
      "phone_number": "+1234567890"
    },
    "relationships": {
      "group": {
        "data": { "type": "groups", "id": "group-uuid" }
      }
    }
  }
}
```

**Fields:**
- `phone_number` (string, required): E.164 format phone number (e.g., `+1234567890`)
- `group_id` (uuid, required): Group ID (must allow registration)

**Response:** `201 Created`
```json
{
  "data": {
    "type": "sms_auths",
    "id": "sms-auth-uuid",
    "attributes": {
      "status": "pending",
      "last_otp_sent_at": "2025-11-19T14:30:00Z",
      "otp_attempts": 0,
      "inserted_at": "2025-11-19T14:30:00Z",
      "updated_at": "2025-11-19T14:30:00Z"
    },
    "relationships": {
      "group": {
        "data": { "type": "groups", "id": "group-uuid" }
      }
    }
  }
}
```

**Note:** The phone number is encrypted and not returned in responses. The OTP code is sent to the phone number via the realm's webhook.

#### Resend OTP

Resend OTP code for an existing SMS auth.

**Endpoint:** `PATCH /sms_auths/:id/resend_otp`  
**Auth:** Public or Machine Token

**Request Body:**
```json
{
  "data": {
    "type": "sms_auths",
    "id": "sms-auth-uuid",
    "attributes": {}
  }
}
```

**Response:** `200 OK`

**Rate Limiting:** Subject to realm rate limits (default: 5 attempts per 5 minutes).

**Note:** Machine tokens can be used to resend OTP codes via webhooks for automation purposes.

#### Verify OTP

Verify the OTP code and complete registration.

**Endpoint:** `PATCH /sms_auths/:id/verify_otp`  
**Auth:** Public

**Request Body:**
```json
{
  "data": {
    "type": "sms_auths",
    "id": "sms-auth-uuid",
    "attributes": {
      "otp": "123456",
      "user_params": {
        "first_name": "John",
        "last_name": "Doe",
        "custom_fields": {}
      }
    }
  }
}
```

**Fields:**
- `otp` (string, required): 6-digit OTP code
- `user_params` (object, optional): User profile information

**Response:** `200 OK`
```json
{
  "data": {
    "type": "sms_auths",
    "id": "sms-auth-uuid",
    "attributes": {
      "status": "verified",
      "otp_attempts": 0,
      "inserted_at": "2025-11-19T14:30:00Z",
      "updated_at": "2025-11-19T14:30:00Z"
    },
    "relationships": {
      "user": {
        "data": { "type": "users", "id": "user-uuid" }
      }
    }
  },
  "included": [
    {
      "type": "users",
      "id": "user-uuid",
      "attributes": {
        "first_name": "John",
        "last_name": "Doe",
        "role": "user"
      }
    }
  ],
  "meta": {
    "access_token": "eyJhbGciOiJIUzI1NiIs...",
    "refresh_token": "base64-encoded-token...",
    "expires_in": 7776000
  }
}
```

**Security:** OTP verification uses constant-time comparison to prevent timing attacks.

---

### Email Authentication

Email-based authentication using magic links.

#### Register with Email

Start email registration process. Sends magic link to the provided email via webhook.

**Endpoint:** `POST /email_auths`  
**Auth:** Public (requires group_id for group that allows registration)  
**Action:** `register`

**Request Body:**
```json
{
  "data": {
    "type": "email_auths",
    "attributes": {
      "email": "user@example.com"
    },
    "relationships": {
      "group": {
        "data": { "type": "groups", "id": "group-uuid" }
      }
    }
  }
}
```

**Fields:**
- `email` (string, required): Valid email address
- `group_id` (uuid, required): Group ID (must allow registration)

**Response:** `201 Created`
```json
{
  "data": {
    "type": "email_auths",
    "id": "email-auth-uuid",
    "attributes": {
      "status": "pending",
      "inserted_at": "2025-11-19T14:30:00Z",
      "updated_at": "2025-11-19T14:30:00Z"
    },
    "relationships": {
      "group": {
        "data": { "type": "groups", "id": "group-uuid" }
      }
    }
  }
}
```

**Note:** The email is encrypted and not returned in responses. The magic link is sent via the realm's webhook. Links expire after 10 minutes.

#### Resend Magic Link

Resend magic link for an existing email auth.

**Endpoint:** `PATCH /email_auths/:id/resend_magic_link`  
**Auth:** Public or Machine Token

**Request Body:**
```json
{
  "data": {
    "type": "email_auths",
    "id": "email-auth-uuid",
    "attributes": {}
  }
}
```

**Response:** `200 OK`

**Note:** Machine tokens can be used to resend magic links via webhooks for automation purposes.

#### Verify Magic Link Token

Verify the magic link token and complete registration.

**Endpoint:** `PATCH /email_auths/:id/verify_token`  
**Auth:** Public

**Request Body:**
```json
{
  "data": {
    "type": "email_auths",
    "id": "email-auth-uuid",
    "attributes": {
      "token": "base64-encoded-token",
      "user_params": {
        "first_name": "Jane",
        "last_name": "Smith",
        "custom_fields": {}
      }
    }
  }
}
```

**Fields:**
- `token` (string, required): Token from magic link URL
- `user_params` (object, optional): User profile information

**Response:** `200 OK`
```json
{
  "data": {
    "type": "email_auths",
    "id": "email-auth-uuid",
    "attributes": {
      "status": "verified",
      "inserted_at": "2025-11-19T14:30:00Z",
      "updated_at": "2025-11-19T14:30:00Z"
    },
    "relationships": {
      "user": {
        "data": { "type": "users", "id": "user-uuid" }
      }
    }
  },
  "included": [
    {
      "type": "users",
      "id": "user-uuid",
      "attributes": {
        "first_name": "Jane",
        "last_name": "Smith",
        "role": "user"
      }
    }
  ],
  "meta": {
    "access_token": "eyJhbGciOiJIUzI1NiIs...",
    "refresh_token": "base64-encoded-token...",
    "expires_in": 7776000
  }
}
```

**Security:** Token verification includes:
- Constant-time comparison
- Expiration check (10 minutes)
- Nonce-based replay attack prevention

---

### Tokens

JWT tokens for authentication and authorization.

#### Create Token

Create a new refresh token for a user (internal use - typically created during auth).

**Endpoint:** `POST /tokens`  
**Auth:** User

**Request Body:**
```json
{
  "data": {
    "type": "tokens",
    "attributes": {
      "expires_at": "2025-12-19T14:30:00Z"
    },
    "relationships": {
      "user": {
        "data": { "type": "users", "id": "user-uuid" }
      }
    }
  }
}
```

**Response:** `201 Created`
```json
{
  "data": {
    "type": "tokens",
    "id": "token-uuid",
    "attributes": {
      "token_family": "family-uuid",
      "expires_at": "2025-12-19T14:30:00Z",
      "revoked": false,
      "revoked_at": null,
      "inserted_at": "2025-11-19T14:30:00Z",
      "updated_at": "2025-11-19T14:30:00Z"
    }
  },
  "meta": {
    "refresh_token": "base64-encoded-token..."
  }
}
```

#### Rotate Token

Rotate an existing refresh token (refresh the access token).

**Endpoint:** `PATCH /tokens/:id`  
**Auth:** User  
**Action:** `rotate`

**Request Body:**
```json
{
  "data": {
    "type": "tokens",
    "id": "token-uuid",
    "attributes": {}
  }
}
```

**Response:** `200 OK`
```json
{
  "data": {
    "type": "tokens",
    "id": "new-token-uuid",
    "attributes": {
      "token_family": "family-uuid",
      "expires_at": "2025-12-19T14:30:00Z",
      "revoked": false,
      "inserted_at": "2025-11-19T14:30:00Z",
      "updated_at": "2025-11-19T14:30:00Z"
    }
  },
  "meta": {
    "access_token": "eyJhbGciOiJIUzI1NiIs...",
    "refresh_token": "new-base64-token...",
    "expires_in": 7776000
  }
}
```

**Note:** The old token is automatically revoked. Token families track rotation lineage.

#### Revoke Token

Manually revoke a token (logout).

**Endpoint:** `PATCH /tokens/:id`  
**Auth:** User  
**Action:** `revoke`

**Request Body:**
```json
{
  "data": {
    "type": "tokens",
    "id": "token-uuid",
    "attributes": {
      "revoked": true
    }
  }
}
```

**Response:** `200 OK`

#### List Tokens

Get all tokens for the current user.

**Endpoint:** `GET /tokens`  
**Auth:** User

**Response:** `200 OK`
```json
{
  "data": [
    {
      "type": "tokens",
      "id": "token-uuid",
      "attributes": {
        "token_family": "family-uuid",
        "expires_at": "2025-12-19T14:30:00Z",
        "revoked": false,
        "is_expired": false,
        "is_valid": true,
        "inserted_at": "2025-11-19T14:30:00Z",
        "updated_at": "2025-11-19T14:30:00Z"
      }
    }
  ]
}
```

---

### Machine Tokens

Machine tokens provide long-lived authentication for CI/CD pipelines, integrations, and automation scripts.

**Important:** Machine tokens are ONLY created via the admin dashboard, not through the API. This endpoint documentation is for using machine tokens in API requests.

#### Using Machine Tokens

Include the machine token in the request header:

```http
X-Kepster-Key: <realm-api-key>
X-Machine-Token: <machine-token-value>
Content-Type: application/vnd.api+json
Accept: application/vnd.api+json
```

Machine tokens automatically authenticate as an admin user and can perform any admin operation.

#### Example: Create User with Machine Token

**Request:**
```bash
curl -X POST https://your-xkepster.com/api/json/users \
  -H "Content-Type: application/vnd.api+json" \
  -H "Accept: application/vnd.api+json" \
  -H "X-Kepster-Key: your-realm-api-key" \
  -H "X-Machine-Token: your-machine-token" \
  -d '{
    "data": {
      "type": "users",
      "attributes": {
        "first_name": "John",
        "last_name": "Doe",
        "role": "user"
      }
    }
  }'
```

#### Machine Token Features

- **Long-lived**: Configurable expiration (30-365 days)
- **Reusable**: Can be used multiple times
- **Tracked**: Last usage timestamp recorded
- **Revocable**: Can be manually revoked via admin dashboard
- **Admin-level**: Full admin permissions
- **Multi-tenant**: Scoped to the realm

#### Security Considerations

1. **Store securely**: Treat machine tokens like passwords
2. **Rotate regularly**: Create new tokens and revoke old ones periodically
3. **Monitor usage**: Check last_used_at timestamps in admin dashboard
4. **Limit scope**: Create separate tokens for different systems
5. **Revoke immediately**: If a token is compromised, revoke it instantly

#### Token Priority

If both a bearer token and machine token are provided:
- Bearer token takes precedence
- Machine token is only used if no bearer token is present

---

### Sessions

Track active user sessions for security and management.

#### Create Session

Create a new session (typically done during authentication).

**Endpoint:** `POST /sessions`  
**Auth:** User

**Request Body:**
```json
{
  "data": {
    "type": "sessions",
    "attributes": {
      "ip_address": "192.168.1.1",
      "user_agent": "Mozilla/5.0...",
      "device_name": "iPhone 14 Pro"
    },
    "relationships": {
      "user": {
        "data": { "type": "users", "id": "user-uuid" }
      }
    }
  }
}
```

**Fields:**
- `ip_address` (string, optional): Client IP address
- `user_agent` (string, optional): Browser/client user agent
- `device_name` (string, optional): Human-readable device name

**Response:** `201 Created`
```json
{
  "data": {
    "type": "sessions",
    "id": "session-uuid",
    "attributes": {
      "ip_address": "192.168.1.1",
      "user_agent": "Mozilla/5.0...",
      "device_name": "iPhone 14 Pro",
      "active": true,
      "last_activity_at": "2025-11-19T14:30:00Z",
      "inserted_at": "2025-11-19T14:30:00Z",
      "updated_at": "2025-11-19T14:30:00Z"
    }
  }
}
```

#### List Sessions

Get all active sessions for the current user.

**Endpoint:** `GET /sessions`  
**Auth:** User

**Query Parameters:**
- `filter[active]` (boolean): Filter by active status

**Response:** `200 OK`
```json
{
  "data": [
    {
      "type": "sessions",
      "id": "session-uuid",
      "attributes": {
        "ip_address": "192.168.1.1",
        "user_agent": "Mozilla/5.0...",
        "device_name": "iPhone 14 Pro",
        "active": true,
        "last_activity_at": "2025-11-19T14:30:00Z",
        "inserted_at": "2025-11-19T14:30:00Z",
        "updated_at": "2025-11-19T14:30:00Z"
      }
    }
  ]
}
```

#### Get Session

**Endpoint:** `GET /sessions/:id`  
**Auth:** User (own sessions only)

**Response:** `200 OK`

#### Revoke Session

End a session (logout from a specific device).

**Endpoint:** `PATCH /sessions/:id`  
**Auth:** User  
**Action:** `revoke`

**Request Body:**
```json
{
  "data": {
    "type": "sessions",
    "id": "session-uuid",
    "attributes": {
      "active": false
    }
  }
}
```

**Response:** `200 OK`

#### Update Session Activity

Update the last activity timestamp.

**Endpoint:** `PATCH /sessions/:id`  
**Auth:** User  
**Action:** `update_activity`

**Request Body:**
```json
{
  "data": {
    "type": "sessions",
    "id": "session-uuid",
    "attributes": {}
  }
}
```

**Response:** `200 OK`

---

### Operation Tokens

One-time tokens for sensitive operations requiring additional verification.

#### Create Operation Token

Generate a token for a sensitive operation.

**Endpoint:** `POST /operation_tokens`  
**Auth:** User or Admin

**Request Body:**
```json
{
  "data": {
    "type": "operation_tokens",
    "attributes": {
      "purpose": "user_delete",
      "expires_at": "2025-11-19T15:30:00Z",
      "metadata": {
        "target_user_id": "user-uuid-to-delete",
        "reason": "User request"
      }
    },
    "relationships": {
      "user": {
        "data": { "type": "users", "id": "current-user-uuid" }
      }
    }
  }
}
```

**Fields:**
- `purpose` (enum, required): One of:
  - `user_delete`
  - `user_update`
  - `user_role_change`
  - `group_delete`
  - `group_update`
  - `realm_settings_update`
- `expires_at` (datetime, required): Token expiration time
- `metadata` (object, optional): Additional context for the operation

**Response:** `201 Created`
```json
{
  "data": {
    "type": "operation_tokens",
    "id": "op-token-uuid",
    "attributes": {
      "purpose": "user_delete",
      "expires_at": "2025-11-19T15:30:00Z",
      "used_at": null,
      "metadata": {
        "target_user_id": "user-uuid-to-delete",
        "reason": "User request"
      },
      "inserted_at": "2025-11-19T14:30:00Z",
      "updated_at": "2025-11-19T14:30:00Z"
    }
  },
  "meta": {
    "token": "base64-encoded-operation-token"
  }
}
```

**Note:** The token value is only returned once at creation time.

#### Verify and Consume Operation Token

Verify a token and mark it as used (one-time use).

**Endpoint:** `PATCH /operation_tokens/:id`  
**Auth:** Public  
**Action:** `verify_and_consume`

**Request Body:**
```json
{
  "data": {
    "type": "operation_tokens",
    "id": "op-token-uuid",
    "attributes": {
      "token": "base64-encoded-operation-token",
      "purpose": "user_delete"
    }
  }
}
```

**Fields:**
- `token` (string, required): The operation token value
- `purpose` (enum, required): Must match the token's purpose

**Response:** `200 OK`
```json
{
  "data": {
    "type": "operation_tokens",
    "id": "op-token-uuid",
    "attributes": {
      "purpose": "user_delete",
      "expires_at": "2025-11-19T15:30:00Z",
      "used_at": "2025-11-19T14:45:00Z",
      "metadata": {
        "target_user_id": "user-uuid-to-delete"
      },
      "inserted_at": "2025-11-19T14:30:00Z",
      "updated_at": "2025-11-19T14:45:00Z"
    }
  }
}
```

**Error Cases:**
- Token already used: `422 Unprocessable Entity`
- Token expired: `422 Unprocessable Entity`
- Invalid token: `422 Unprocessable Entity`
- Purpose mismatch: `422 Unprocessable Entity`

**Security:** Uses constant-time comparison to prevent timing attacks.

#### List Operation Tokens

Get operation tokens for the current user.

**Endpoint:** `GET /operation_tokens`  
**Auth:** User

**Response:** `200 OK`

---

### Audit Logs

Comprehensive audit trail of security-relevant events.

#### List Audit Logs

Retrieve audit logs (Admin only).

**Endpoint:** `GET /audit_logs`  
**Auth:** Admin

**Query Parameters:**
- `page[limit]` (integer): Number of results per page
- `page[offset]` (integer): Offset for pagination
- `filter[event_type]` (string): Filter by event type
- `filter[actor_id]` (uuid): Filter by actor ID
- `filter[resource_type]` (string): Filter by resource type
- `sort` (string): Sort field (default: `-occurred_at`)

**Response:** `200 OK`
```json
{
  "data": [
    {
      "type": "audit_logs",
      "id": "audit-log-uuid",
      "attributes": {
        "event_type": "user_created",
        "actor_id": "admin-user-uuid",
        "actor_type": "user",
        "resource_id": "new-user-uuid",
        "resource_type": "user",
        "ip_address": "192.168.1.1",
        "user_agent": "Mozilla/5.0...",
        "metadata": {
          "first_name": "John",
          "role": "user"
        },
        "occurred_at": "2025-11-19T14:30:00Z",
        "inserted_at": "2025-11-19T14:30:00Z",
        "updated_at": "2025-11-19T14:30:00Z"
      }
    }
  ]
}
```

**Event Types:**
- `user_created`
- `user_updated`
- `user_locked`
- `user_unlocked`
- `user_promoted`
- `user_deleted`
- `sms_auth_registered`
- `sms_auth_verified`
- `sms_otp_failed`
- `email_auth_registered`
- `email_auth_verified`
- `email_token_failed`
- `token_issued`
- `token_rotated`
- `token_revoked`
- `session_created`
- `session_revoked`
- `group_created`
- `group_updated`
- `group_deleted`

#### Get Audit Log

**Endpoint:** `GET /audit_logs/:id`  
**Auth:** Admin

**Response:** `200 OK`

#### Get Audit Logs for User

Get audit logs for a specific user.

**Endpoint:** `GET /audit_logs?filter[actor_id]=<user-uuid>&filter[actor_type]=user`  
**Auth:** Admin

**Response:** `200 OK`

#### Get Audit Logs by Event Type

**Endpoint:** `GET /audit_logs?filter[event_type]=user_created`  
**Auth:** Admin

**Response:** `200 OK`

---

### Realm

Get information about the current realm (identified by API key).

#### Get Current Realm

**Endpoint:** `GET /realm`  
**Auth:** Admin

**Response:** `200 OK`
```json
{
  "data": {
    "type": "realm",
    "id": "realm-uuid",
    "attributes": {
      "name": "My Company",
      "slug": "my_company",
      "status": "active",
      "webhook_url": "https://my-company.com/webhooks/xkepster",
      "rate_limit_window": 300,
      "rate_limit_max_attempts": 5,
      "token_expiry_seconds": 7776000,
      "require_idempotency_keys": false,
      "require_request_timestamps": false,
      "require_signed_requests": false,
      "timestamp_tolerance_seconds": 300,
      "signature_tolerance_seconds": 300,
      "inserted_at": "2025-11-01T10:00:00Z",
      "updated_at": "2025-11-15T12:30:00Z"
    }
  }
}
```

**Note:** This endpoint returns the realm associated with the API key used in the request. Sensitive fields (api_key, shared_secret, webhook_secret) are never returned.

---

## Security Features

### Replay Attack Prevention

Xkepster supports three optional security measures for replay attack prevention:

#### 1. Idempotency Keys

For mutating operations (POST, PATCH, DELETE), include a unique idempotency key:

**Header:**
```
X-Idempotency-Key: unique-request-id-123
```

- Keys are cached for the duration of the request
- Duplicate requests with the same key within the window return the cached response
- Required if `realm.require_idempotency_keys` is true

#### 2. Request Timestamps

Include a timestamp with each request:

**Header:**
```
X-Request-Timestamp: 2025-11-19T14:30:00Z
```

- Timestamp must be within the tolerance window (default: 5 minutes)
- Prevents replay of old requests
- Required if `realm.require_request_timestamps` is true

#### 3. Request Signatures

Sign requests using HMAC-SHA256 with the realm's shared secret:

**Header:**
```
X-Request-Signature: hmac-sha256-signature
```

**Signature Calculation:**
```
signature = HMAC-SHA256(
  key: realm.shared_secret,
  message: "#{method}|#{path}|#{timestamp}|#{body}"
)
```

**Example (pseudo-code):**
```
method = "POST"
path = "/api/json/users"
timestamp = "2025-11-19T14:30:00Z"
body = '{"data":{"type":"users",...}}'

message = "POST|/api/json/users|2025-11-19T14:30:00Z|{...}"
signature = hmac_sha256(shared_secret, message)
```

- Required if `realm.require_signed_requests` is true
- Signature must be within the tolerance window (default: 5 minutes)

### Encryption

Sensitive data is encrypted at rest:

- Phone numbers: AES-GCM encryption
- Emails: AES-GCM encryption
- TOTP secrets: AES-GCM encryption
- Tokens: Stored as binary, never exposed

### Hashing

PII is hashed for lookups:

- Phone numbers: HMAC-SHA256 hash
- Emails: HMAC-SHA256 hash
- Prevents rainbow table attacks

### Constant-Time Comparisons

All sensitive comparisons use constant-time algorithms:

- OTP verification
- Token verification
- Password/secret comparison

---

## Webhooks

Xkepster uses webhooks to deliver OTP codes and magic links to your infrastructure.

### Webhook Configuration

Configure webhook URL at realm level:
- Set `webhook_url` when creating/updating realm
- Include `webhook_secret` for HMAC signature verification

### Webhook Payloads

#### OTP Delivery (SMS)

**POST** to `webhook_url`

**Headers:**
```
Content-Type: application/json
X-Webhook-Signature: hmac-sha256-signature
X-Webhook-Event: otp
```

**Body:**
```json
{
  "type": "otp",
  "recipient": "+1234567890",
  "code": "123456",
  "tenant": "tenant_my_company",
  "timestamp": "2025-11-19T14:30:00Z"
}
```

#### Magic Link Delivery (Email)

**POST** to `webhook_url`

**Headers:**
```
Content-Type: application/json
X-Webhook-Signature: hmac-sha256-signature
X-Webhook-Event: magic_link
```

**Body:**
```json
{
  "type": "magic_link",
  "recipient": "user@example.com",
  "link": "https://my-company.example.com/auth/verify?token=...",
  "tenant": "tenant_my_company",
  "timestamp": "2025-11-19T14:30:00Z"
}
```

### Webhook Signature Verification

Verify webhook authenticity using HMAC-SHA256:

```
signature = HMAC-SHA256(
  key: realm.webhook_secret,
  message: request_body
)
```

Compare the computed signature with `X-Webhook-Signature` header using constant-time comparison.

### Webhook Response

Your webhook endpoint should respond with:

**Success:** `200 OK` or `204 No Content`

**Failure:** Any 4xx or 5xx status code

Failed webhook deliveries are logged but do not block the authentication flow.

---

## Rate Limiting

### Configuration

Rate limits are configurable per realm:

- `rate_limit_window` (default: 300 seconds = 5 minutes)
- `rate_limit_max_attempts` (default: 5 attempts)

### Endpoints Subject to Rate Limiting

- SMS OTP resend
- Email magic link resend
- Authentication attempts

### Rate Limit Response

When rate limited:

**Status:** `429 Too Many Requests`

**Body:**
```json
{
  "errors": [
    {
      "status": "429",
      "title": "Too Many Requests",
      "detail": "Rate limit exceeded. Try again after 2025-11-19T14:35:00Z",
      "meta": {
        "reset_at": "2025-11-19T14:35:00Z",
        "retry_after": 180
      }
    }
  ]
}
```

**Headers:**
```
Retry-After: 180
```

---

## Client Implementation Guide

### Ruby Client

#### Recommended Libraries

- **HTTP Client**: `faraday` or `httparty`
- **JSON:API**: `jsonapi-serializer`
- **JWT**: `jwt` gem

#### Example: Basic Setup

```ruby
require 'faraday'
require 'json'

class XkepsterClient
  BASE_URL = 'https://your-xkepster.com/api/json'

  def initialize(api_key, bearer_token: nil, machine_token: nil)
    @api_key = api_key
    @bearer_token = bearer_token
    @machine_token = machine_token
  end

  def connection
    @connection ||= Faraday.new(url: BASE_URL) do |f|
      f.request :json
      f.response :json
      f.adapter Faraday.default_adapter
      f.headers['Content-Type'] = 'application/vnd.api+json'
      f.headers['Accept'] = 'application/vnd.api+json'
      f.headers['X-Kepster-Key'] = @api_key
      f.headers['Authorization'] = "Bearer #{@bearer_token}" if @bearer_token
      f.headers['X-Machine-Token'] = @machine_token if @machine_token
    end
  end
  
  def list_users(limit: 25, offset: 0)
    response = connection.get('/users') do |req|
      req.params['page[limit]'] = limit
      req.params['page[offset]'] = offset
    end
    response.body
  end
  
  def create_user(first_name:, last_name:, role: 'user', custom_fields: {})
    payload = {
      data: {
        type: 'users',
        attributes: {
          first_name: first_name,
          last_name: last_name,
          role: role,
          custom_fields: custom_fields
        }
      }
    }
    
    response = connection.post('/users', payload)
    response.body
  end
  
  def register_sms(phone_number:, group_id:)
    payload = {
      data: {
        type: 'sms_auths',
        attributes: { phone_number: phone_number },
        relationships: {
          group: { data: { type: 'groups', id: group_id } }
        }
      }
    }
    
    response = connection.post('/sms_auths', payload)
    response.body
  end
  
  def resend_otp(sms_auth_id:)
    payload = {
      data: {
        type: 'sms_auths',
        id: sms_auth_id,
        attributes: {}
      }
    }
    
    response = connection.patch("/sms_auths/#{sms_auth_id}/resend_otp", payload)
    response.body
  end
  
  def verify_otp(sms_auth_id:, otp:, user_params: {})
    payload = {
      data: {
        type: 'sms_auths',
        id: sms_auth_id,
        attributes: {
          otp: otp,
          user_params: user_params
        }
      }
    }
    
    response = connection.patch("/sms_auths/#{sms_auth_id}/verify_otp", payload)
    response.body
  end
  
  def resend_magic_link(email_auth_id:)
    payload = {
      data: {
        type: 'email_auths',
        id: email_auth_id,
        attributes: {}
      }
    }
    
    response = connection.patch("/email_auths/#{email_auth_id}/resend_magic_link", payload)
    response.body
  end
  
  def verify_magic_link(email_auth_id:, token:, user_params: {})
    payload = {
      data: {
        type: 'email_auths',
        id: email_auth_id,
        attributes: {
          token: token,
          user_params: user_params
        }
      }
    }
    
    response = connection.patch("/email_auths/#{email_auth_id}/verify_token", payload)
    response.body
  end
end

# Usage

# Public client
client = XkepsterClient.new('your-api-key')
users = client.list_users(limit: 10)

# With bearer token (authenticated user)
auth_client = XkepsterClient.new('your-api-key', bearer_token: 'user-jwt-token')
profile = auth_client.get_user('user-uuid')

# With machine token (CI/CD automation)
machine_client = XkepsterClient.new('your-api-key', machine_token: 'your-machine-token')
new_user = machine_client.create_user(
  first_name: 'Automated',
  last_name: 'User',
  role: 'user'
)
```

---

### Elixir Client

#### Recommended Libraries

- **HTTP Client**: `Req` (already included in Phoenix)
- **JSON:API**: Built-in `Jason`

#### Example: Basic Setup

```elixir
defmodule XkepsterClient do
  @base_url "https://your-xkepster.com/api/json"
  
  def new(api_key, bearer_token \\ nil) do
    headers = [
      {"content-type", "application/vnd.api+json"},
      {"accept", "application/vnd.api+json"},
      {"x-kepster-key", api_key}
    ]
    
    headers = if bearer_token do
      [{"authorization", "Bearer #{bearer_token}"} | headers]
    else
      headers
    end
    
    Req.new(base_url: @base_url, headers: headers)
  end
  
  def list_users(client, opts \\ []) do
    limit = Keyword.get(opts, :limit, 25)
    offset = Keyword.get(opts, :offset, 0)
    
    Req.get!(client, url: "/users", params: [
      "page[limit]": limit,
      "page[offset]": offset
    ])
  end
  
  def create_user(client, attrs) do
    payload = %{
      "data" => %{
        "type" => "users",
        "attributes" => attrs
      }
    }
    
    Req.post!(client, url: "/users", json: payload)
  end
  
  def register_sms(client, phone_number, group_id) do
    payload = %{
      "data" => %{
        "type" => "sms_auths",
        "attributes" => %{"phone_number" => phone_number},
        "relationships" => %{
          "group" => %{"data" => %{"type" => "groups", "id" => group_id}}
        }
      }
    }
    
    Req.post!(client, url: "/sms_auths", json: payload)
  end
  
  def resend_otp(client, sms_auth_id) do
    payload = %{
      "data" => %{
        "type" => "sms_auths",
        "id" => sms_auth_id,
        "attributes" => %{}
      }
    }
    
    Req.patch!(client, url: "/sms_auths/#{sms_auth_id}/resend_otp", json: payload)
  end
  
  def verify_otp(client, sms_auth_id, otp, user_params \\ %{}) do
    payload = %{
      "data" => %{
        "type" => "sms_auths",
        "id" => sms_auth_id,
        "attributes" => %{
          "otp" => otp,
          "user_params" => user_params
        }
      }
    }
    
    Req.patch!(client, url: "/sms_auths/#{sms_auth_id}/verify_otp", json: payload)
  end
  
  def resend_magic_link(client, email_auth_id) do
    payload = %{
      "data" => %{
        "type" => "email_auths",
        "id" => email_auth_id,
        "attributes" => %{}
      }
    }
    
    Req.patch!(client, url: "/email_auths/#{email_auth_id}/resend_magic_link", json: payload)
  end
  
  def verify_magic_link(client, email_auth_id, token, user_params \\ %{}) do
    payload = %{
      "data" => %{
        "type" => "email_auths",
        "id" => email_auth_id,
        "attributes" => %{
          "token" => token,
          "user_params" => user_params
        }
      }
    }
    
    Req.patch!(client, url: "/email_auths/#{email_auth_id}/verify_token", json: payload)
  end
end

# Usage
client = XkepsterClient.new("your-api-key")
{:ok, %{body: users}} = XkepsterClient.list_users(client, limit: 10)

# With bearer token
auth_client = XkepsterClient.new("your-api-key", "user-jwt-token")
{:ok, %{body: profile}} = XkepsterClient.get_user(auth_client, "user-uuid")
```

---

### Flutter Client

#### Recommended Libraries

- **HTTP Client**: `dio` or `http`
- **JSON Serialization**: `json_serializable`
- **State Management**: `riverpod` or `bloc`

#### Example: Basic Setup

```dart
import 'package:dio/dio.dart';

class XkepsterClient {
  final Dio _dio;
  final String apiKey;
  String? bearerToken;
  
  static const String baseUrl = 'https://your-xkepster.com/api/json';
  
  XkepsterClient(this.apiKey, {this.bearerToken}) 
    : _dio = Dio(BaseOptions(
        baseUrl: baseUrl,
        headers: {
          'Content-Type': 'application/vnd.api+json',
          'Accept': 'application/vnd.api+json',
          'X-Kepster-Key': apiKey,
        },
      )) {
    if (bearerToken != null) {
      _dio.options.headers['Authorization'] = 'Bearer $bearerToken';
    }
  }
  
  Future<Map<String, dynamic>> listUsers({
    int limit = 25, 
    int offset = 0
  }) async {
    final response = await _dio.get('/users', queryParameters: {
      'page[limit]': limit,
      'page[offset]': offset,
    });
    return response.data;
  }
  
  Future<Map<String, dynamic>> createUser({
    required String firstName,
    String? lastName,
    String role = 'user',
    Map<String, dynamic>? customFields,
  }) async {
    final payload = {
      'data': {
        'type': 'users',
        'attributes': {
          'first_name': firstName,
          'last_name': lastName,
          'role': role,
          'custom_fields': customFields ?? {},
        }
      }
    };
    
    final response = await _dio.post('/users', data: payload);
    return response.data;
  }
  
  Future<Map<String, dynamic>> registerSms({
    required String phoneNumber,
    required String groupId,
  }) async {
    final payload = {
      'data': {
        'type': 'sms_auths',
        'attributes': {'phone_number': phoneNumber},
        'relationships': {
          'group': {
            'data': {'type': 'groups', 'id': groupId}
          }
        }
      }
    };
    
    final response = await _dio.post('/sms_auths', data: payload);
    return response.data;
  }
  
  Future<Map<String, dynamic>> resendOtp({
    required String smsAuthId,
  }) async {
    final payload = {
      'data': {
        'type': 'sms_auths',
        'id': smsAuthId,
        'attributes': {}
      }
    };
    
    final response = await _dio.patch(
      '/sms_auths/$smsAuthId/resend_otp',
      data: payload
    );
    return response.data;
  }
  
  Future<Map<String, dynamic>> verifyOtp({
    required String smsAuthId,
    required String otp,
    Map<String, dynamic>? userParams,
  }) async {
    final payload = {
      'data': {
        'type': 'sms_auths',
        'id': smsAuthId,
        'attributes': {
          'otp': otp,
          'user_params': userParams ?? {},
        }
      }
    };
    
    final response = await _dio.patch(
      '/sms_auths/$smsAuthId/verify_otp',
      data: payload
    );
    return response.data;
  }
  
  Future<Map<String, dynamic>> resendMagicLink({
    required String emailAuthId,
  }) async {
    final payload = {
      'data': {
        'type': 'email_auths',
        'id': emailAuthId,
        'attributes': {}
      }
    };
    
    final response = await _dio.patch(
      '/email_auths/$emailAuthId/resend_magic_link',
      data: payload
    );
    return response.data;
  }
  
  Future<Map<String, dynamic>> verifyMagicLink({
    required String emailAuthId,
    required String token,
    Map<String, dynamic>? userParams,
  }) async {
    final payload = {
      'data': {
        'type': 'email_auths',
        'id': emailAuthId,
        'attributes': {
          'token': token,
          'user_params': userParams ?? {},
        }
      }
    };
    
    final response = await _dio.patch(
      '/email_auths/$emailAuthId/verify_token',
      data: payload
    );
    return response.data;
  }
}

// Usage
void main() async {
  final client = XkepsterClient('your-api-key');
  
  // List users
  final users = await client.listUsers(limit: 10);
  print('Users: $users');
  
  // Register with SMS
  final smsAuth = await client.registerSms(
    phoneNumber: '+1234567890',
    groupId: 'group-uuid',
  );
  
  // Resend OTP
  await client.resendOtp(smsAuthId: smsAuth['data']['id']);
  
  // Verify OTP
  final result = await client.verifyOtp(
    smsAuthId: smsAuth['data']['id'],
    otp: '123456',
    userParams: {
      'first_name': 'John',
      'last_name': 'Doe',
    },
  );
  
  // Register with Email
  final emailAuth = await client.registerEmail(
    email: 'user@example.com',
    groupId: 'group-uuid',
  );
  
  // Resend Magic Link
  await client.resendMagicLink(emailAuthId: emailAuth['data']['id']);
  
  // Verify Magic Link
  final emailResult = await client.verifyMagicLink(
    emailAuthId: emailAuth['data']['id'],
    token: 'token-from-email-link',
    userParams: {
      'first_name': 'Jane',
      'last_name': 'Smith',
    },
  );
  
  // Update client with bearer token
  client.bearerToken = result['meta']['access_token'];
}
```

---

### JavaScript/TypeScript Client

#### Recommended Libraries

- **HTTP Client**: `axios` or `fetch`
- **TypeScript**: Type definitions for API responses

#### Example: Basic Setup

```typescript
import axios, { AxiosInstance } from 'axios';

interface XkepsterClientConfig {
  apiKey: string;
  bearerToken?: string;
  machineToken?: string;
  baseUrl?: string;
}

interface JsonApiData<T = any> {
  data: {
    type: string;
    id?: string;
    attributes?: T;
    relationships?: any;
  };
  meta?: any;
  included?: any[];
}

interface JsonApiCollection<T = any> {
  data: Array<{
    type: string;
    id: string;
    attributes: T;
  }>;
  links?: {
    self?: string;
    next?: string;
    prev?: string;
  };
  meta?: any;
}

class XkepsterClient {
  private client: AxiosInstance;
  private apiKey: string;
  private bearerToken?: string;
  private machineToken?: string;

  constructor(config: XkepsterClientConfig) {
    this.apiKey = config.apiKey;
    this.bearerToken = config.bearerToken;
    this.machineToken = config.machineToken;

    const baseURL = config.baseUrl || 'https://your-xkepster.com/api/json';

    this.client = axios.create({
      baseURL,
      headers: {
        'Content-Type': 'application/vnd.api+json',
        'Accept': 'application/vnd.api+json',
        'X-Kepster-Key': this.apiKey,
      },
    });

    if (this.bearerToken) {
      this.client.defaults.headers.common['Authorization'] =
        `Bearer ${this.bearerToken}`;
    }

    if (this.machineToken) {
      this.client.defaults.headers.common['X-Machine-Token'] =
        this.machineToken;
    }
  }

  setBearerToken(token: string) {
    this.bearerToken = token;
    this.client.defaults.headers.common['Authorization'] =
      `Bearer ${token}`;
  }

  setMachineToken(token: string) {
    this.machineToken = token;
    this.client.defaults.headers.common['X-Machine-Token'] = token;
  }
  
  async listUsers(options?: {
    limit?: number;
    offset?: number;
    filter?: Record<string, any>;
    sort?: string;
    include?: string;
  }): Promise<JsonApiCollection> {
    const params = {
      'page[limit]': options?.limit || 25,
      'page[offset]': options?.offset || 0,
      ...(options?.filter && Object.entries(options.filter).reduce(
        (acc, [key, value]) => ({
          ...acc,
          [`filter[${key}]`]: value
        }), {}
      )),
      ...(options?.sort && { sort: options.sort }),
      ...(options?.include && { include: options.include }),
    };
    
    const response = await this.client.get('/users', { params });
    return response.data;
  }
  
  async createUser(data: {
    firstName: string;
    lastName?: string;
    role?: 'user' | 'admin';
    customFields?: Record<string, any>;
    groupIds?: string[];
  }): Promise<JsonApiData> {
    const payload: JsonApiData = {
      data: {
        type: 'users',
        attributes: {
          first_name: data.firstName,
          last_name: data.lastName,
          role: data.role || 'user',
          custom_fields: data.customFields || {},
        },
      },
    };
    
    if (data.groupIds && data.groupIds.length > 0) {
      payload.data.relationships = {
        groups: {
          data: data.groupIds.map(id => ({ type: 'groups', id }))
        }
      };
    }
    
    const response = await this.client.post('/users', payload);
    return response.data;
  }
  
  async registerSms(data: {
    phoneNumber: string;
    groupId: string;
  }): Promise<JsonApiData> {
    const payload: JsonApiData = {
      data: {
        type: 'sms_auths',
        attributes: {
          phone_number: data.phoneNumber,
        },
        relationships: {
          group: {
            data: { type: 'groups', id: data.groupId }
          }
        }
      }
    };
    
    const response = await this.client.post('/sms_auths', payload);
    return response.data;
  }
  
  async resendOtp(data: {
    smsAuthId: string;
  }): Promise<JsonApiData> {
    const payload: JsonApiData = {
      data: {
        type: 'sms_auths',
        id: data.smsAuthId,
        attributes: {}
      }
    };
    
    const response = await this.client.patch(
      `/sms_auths/${data.smsAuthId}/resend_otp`,
      payload
    );
    return response.data;
  }
  
  async verifyOtp(data: {
    smsAuthId: string;
    otp: string;
    userParams?: {
      firstName?: string;
      lastName?: string;
      customFields?: Record<string, any>;
    };
  }): Promise<JsonApiData> {
    const payload: JsonApiData = {
      data: {
        type: 'sms_auths',
        id: data.smsAuthId,
        attributes: {
          otp: data.otp,
          user_params: data.userParams || {},
        }
      }
    };
    
    const response = await this.client.patch(
      `/sms_auths/${data.smsAuthId}/verify_otp`,
      payload
    );
    return response.data;
  }
  
  async registerEmail(data: {
    email: string;
    groupId: string;
  }): Promise<JsonApiData> {
    const payload: JsonApiData = {
      data: {
        type: 'email_auths',
        attributes: { email: data.email },
        relationships: {
          group: {
            data: { type: 'groups', id: data.groupId }
          }
        }
      }
    };
    
    const response = await this.client.post('/email_auths', payload);
    return response.data;
  }
  
  async resendMagicLink(data: {
    emailAuthId: string;
  }): Promise<JsonApiData> {
    const payload: JsonApiData = {
      data: {
        type: 'email_auths',
        id: data.emailAuthId,
        attributes: {}
      }
    };
    
    const response = await this.client.patch(
      `/email_auths/${data.emailAuthId}/resend_magic_link`,
      payload
    );
    return response.data;
  }
  
  async verifyMagicLink(data: {
    emailAuthId: string;
    token: string;
    userParams?: {
      firstName?: string;
      lastName?: string;
      customFields?: Record<string, any>;
    };
  }): Promise<JsonApiData> {
    const payload: JsonApiData = {
      data: {
        type: 'email_auths',
        id: data.emailAuthId,
        attributes: {
          token: data.token,
          user_params: data.userParams || {},
        }
      }
    };
    
    const response = await this.client.patch(
      `/email_auths/${data.emailAuthId}/verify_token`,
      payload
    );
    return response.data;
  }
  
  async listSessions(active?: boolean): Promise<JsonApiCollection> {
    const params = active !== undefined ? 
      { 'filter[active]': active } : {};
    
    const response = await this.client.get('/sessions', { params });
    return response.data;
  }
  
  async revokeSession(sessionId: string): Promise<JsonApiData> {
    const payload: JsonApiData = {
      data: {
        type: 'sessions',
        id: sessionId,
        attributes: { active: false }
      }
    };
    
    const response = await this.client.patch(
      `/sessions/${sessionId}`,
      payload
    );
    return response.data;
  }
  
  async getCurrentRealm(): Promise<JsonApiData> {
    const response = await this.client.get('/realm');
    return response.data;
  }
}

// Usage

// Public client
const client = new XkepsterClient({
  apiKey: 'your-api-key'
});

// List users
const users = await client.listUsers({
  limit: 10,
  sort: '-inserted_at'
});

// Register with SMS
const smsAuth = await client.registerSms({
  phoneNumber: '+1234567890',
  groupId: 'group-uuid',
});

// Resend OTP
await client.resendOtp({
  smsAuthId: smsAuth.data.id!,
});

// Verify OTP
const result = await client.verifyOtp({
  smsAuthId: smsAuth.data.id!,
  otp: '123456',
  userParams: {
    firstName: 'John',
    lastName: 'Doe',
  },
});

// Register with Email
const emailAuth = await client.registerEmail({
  email: 'user@example.com',
  groupId: 'group-uuid',
});

// Resend Magic Link
await client.resendMagicLink({
  emailAuthId: emailAuth.data.id!,
});

// Verify Magic Link
const emailResult = await client.verifyMagicLink({
  emailAuthId: emailAuth.data.id!,
  token: 'token-from-email-link',
  userParams: {
    firstName: 'Jane',
    lastName: 'Smith',
  },
});

// Set bearer token from auth result
client.setBearerToken(result.meta.access_token);

// Now make authenticated requests
const profile = await client.listUsers();

// CI/CD automation with machine token
const machineClient = new XkepsterClient({
  apiKey: 'your-api-key',
  machineToken: 'your-machine-token'
});

// Create users automatically
const newUser = await machineClient.createUser({
  firstName: 'Automated',
  lastName: 'User',
  role: 'user'
});

// Machine tokens can also resend OTP/magic links via webhooks
await machineClient.resendOtp({ smsAuthId: 'sms-auth-uuid' });
await machineClient.resendMagicLink({ emailAuthId: 'email-auth-uuid' });
```

---

## Additional Notes

### Testing

All clients should implement:

1. **Unit tests** for request/response formatting
2. **Integration tests** against a test realm
3. **Error handling tests** for all error cases
4. **Rate limit handling** with exponential backoff

### Best Practices

1. **Store API keys securely** (environment variables, secure storage)
2. **Implement token refresh logic** before tokens expire
3. **Handle rate limits gracefully** with retry logic
4. **Validate inputs** before sending requests
5. **Use constant-time comparisons** for sensitive data
6. **Implement proper error handling** for all API calls
7. **Cache realm configuration** to avoid unnecessary requests
8. **Implement request/response logging** for debugging
9. **Use connection pooling** for better performance
10. **Implement timeout handling** for long-running requests

### Pagination

For endpoints that return collections:

```javascript
async function getAllUsers(client) {
  let allUsers = [];
  let offset = 0;
  const limit = 100;
  let hasMore = true;
  
  while (hasMore) {
    const response = await client.listUsers({ limit, offset });
    allUsers.push(...response.data);
    
    hasMore = response.links?.next !== undefined;
    offset += limit;
  }
  
  return allUsers;
}
```

### Error Recovery

Implement exponential backoff for rate limits:

```javascript
async function withRetry(fn, maxRetries = 3) {
  for (let i = 0; i < maxRetries; i++) {
    try {
      return await fn();
    } catch (error) {
      if (error.response?.status === 429) {
        const retryAfter = error.response.headers['retry-after'] || 
          Math.pow(2, i) * 1000;
        await new Promise(resolve => setTimeout(resolve, retryAfter));
      } else {
        throw error;
      }
    }
  }
  throw new Error('Max retries exceeded');
}
```

---

## Changelog

### Version 1.2.0 (2025-12-17)

- **Route Updates**: Updated authentication endpoints to use explicit action routes
  - `PATCH /sms_auths/:id/resend_otp` - Resend OTP (was `PATCH /sms_auths/:id` with action)
  - `PATCH /sms_auths/:id/verify_otp` - Verify OTP (was `PATCH /sms_auths/:id` with action)
  - `PATCH /email_auths/:id/resend_magic_link` - Resend magic link (was `PATCH /email_auths/:id` with action)
  - `PATCH /email_auths/:id/verify_token` - Verify token (was `PATCH /email_auths/:id` with action)
- **Machine Token Support**: Machine tokens can now be used to resend OTP codes and magic links via webhooks
  - Enables automation workflows for authentication flows
  - Supports CI/CD pipelines that need to trigger authentication webhooks

### Version 1.1.0 (2025-11-25)

- **Machine Tokens**: Long-lived authentication tokens for CI/CD and automation
  - Created via admin dashboard
  - Configurable expiration (30-365 days)
  - Usage tracking (last_used_at)
  - Manual revocation support
  - Admin-level permissions

### Version 1.0.0 (2025-11-19)

- Initial API specification
- Full JSON:API compliance
- Multi-tenant architecture
- SMS and Email authentication
- Token management with rotation
- Session tracking
- Operation tokens
- Audit logging
- Security features (replay attack prevention)
- Webhook integration

---

## Support

For questions, issues, or feature requests:

- GitHub: https://github.com/your-org/xkepster
- Email: support@your-xkepster.com
- Documentation: https://docs.your-xkepster.com

---

## License

Copyright © 2025 Xkepster. All rights reserved.

