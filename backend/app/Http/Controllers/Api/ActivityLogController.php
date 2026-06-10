<?php

namespace App\Http\Controllers\Api;

use App\Http\Controllers\Controller;
use App\Models\ActivityLog;
use Illuminate\Http\Request;

class ActivityLogController extends Controller
{
    public function index(Request $request)
    {
        $search = $request->query('search');
        $perPage = $request->query('per_page', 15);
        $sortKey = $request->query('sort_key', 'created_at');
        $sortDir = $request->query('sort_dir', 'desc');

        $query = ActivityLog::with('user');

        if ($search) {
            $query->where('action', 'like', "%{$search}%")
                  ->orWhere('detail', 'like', "%{$search}%")
                  ->orWhereHas('user', function($q) use ($search) {
                      $q->where('name', 'like', "%{$search}%");
                  });
        }

        if (in_array($sortKey, ['action', 'created_at'])) {
            $query->orderBy($sortKey, $sortDir);
        } else {
            $query->latest();
        }

        $logs = $query->paginate($perPage);
        
        $logs->getCollection()->transform(function ($log) {
            return [
                'id' => $log->id,
                'action' => $log->action,
                'detail' => $log->detail,
                'time' => $log->created_at->diffForHumans(),
                'created_at' => $log->created_at->toIso8601String(),
                'status' => $log->status,
                'user_name' => $log->user ? $log->user->name : 'Sistem',
            ];
        });

        return response()->json([
            'success' => true,
            'data' => $logs
        ]);
    }
}
