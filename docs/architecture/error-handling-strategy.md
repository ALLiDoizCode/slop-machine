# Error Handling Strategy

## Error Response Format

```typescript
interface ApiError {
  error: {
    code: string;
    message: string;
    details?: Record<string, any>;
    timestamp: string;
    requestId: string;
  };
}
```

## Standard Error Codes

- `VOUCHER_EXPIRED`
- `INSUFFICIENT_BALANCE`
- `NILLION_UNAVAILABLE`
- `CHANNEL_NOT_FOUND`
- `AUTH_FAILED`

---
