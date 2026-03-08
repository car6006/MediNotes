<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Support\Arr;
use Illuminate\Support\Facades\DB;
use Illuminate\Support\Facades\Schema;

return new class extends Migration
{
    /**
     * Run the migrations.
     */
    public function up(): void
    {
        if (! Schema::hasTable('roles') || ! Schema::hasTable('permissions')) {
            return;
        }

        $now = now();
        $permissionDefinitions = collect(config('rbac.permissions', []));
        $roleDefinitions = collect(config('rbac.roles', []));

        DB::table('permissions')->upsert(
            $permissionDefinitions
                ->map(fn (array $permission): array => [
                    'name' => $permission['name'],
                    'slug' => $permission['slug'],
                    'group' => $permission['group'] ?? null,
                    'description' => $permission['description'] ?? null,
                    'created_at' => $now,
                    'updated_at' => $now,
                ])
                ->all(),
            ['slug'],
            ['name', 'group', 'description', 'updated_at'],
        );

        DB::table('roles')->upsert(
            $roleDefinitions
                ->map(fn (array $role, string $slug): array => [
                    'name' => $role['name'],
                    'slug' => $slug,
                    'description' => $role['description'] ?? null,
                    'is_system' => (bool) ($role['is_system'] ?? true),
                    'created_at' => $now,
                    'updated_at' => $now,
                ])
                ->values()
                ->all(),
            ['slug'],
            ['name', 'description', 'is_system', 'updated_at'],
        );

        $permissionIds = DB::table('permissions')->pluck('id', 'slug');
        $roleIds = DB::table('roles')->pluck('id', 'slug');
        $permissionPivot = [];

        foreach ($roleDefinitions as $slug => $role) {
            $roleId = $roleIds[$slug] ?? null;

            if (! $roleId) {
                continue;
            }

            $permissionSlugs = Arr::get($role, 'permissions', []);

            if ($permissionSlugs === '*') {
                $permissionSlugs = $permissionIds->keys()->all();
            }

            foreach ((array) $permissionSlugs as $permissionSlug) {
                $permissionId = $permissionIds[$permissionSlug] ?? null;

                if (! $permissionId) {
                    continue;
                }

                $permissionPivot[] = [
                    'permission_id' => $permissionId,
                    'role_id' => $roleId,
                    'created_at' => $now,
                    'updated_at' => $now,
                ];
            }
        }

        if ($permissionPivot !== [] && Schema::hasTable('permission_role')) {
            DB::table('permission_role')->upsert(
                $permissionPivot,
                ['permission_id', 'role_id'],
                ['updated_at'],
            );
        }

        if (! Schema::hasTable('role_user')) {
            return;
        }

        $roleUserPivot = DB::table('users')
            ->whereNotNull('role')
            ->get(['id', 'role'])
            ->map(function (object $user) use ($roleIds, $now): ?array {
                $roleId = $roleIds[$user->role] ?? null;

                if (! $roleId) {
                    return null;
                }

                return [
                    'role_id' => $roleId,
                    'user_id' => $user->id,
                    'created_at' => $now,
                    'updated_at' => $now,
                ];
            })
            ->filter()
            ->values()
            ->all();

        if ($roleUserPivot !== []) {
            DB::table('role_user')->upsert(
                $roleUserPivot,
                ['role_id', 'user_id'],
                ['updated_at'],
            );
        }
    }

    /**
     * Reverse the migrations.
     */
    public function down(): void
    {
        if (! Schema::hasTable('roles') || ! Schema::hasTable('permissions')) {
            return;
        }

        $roleSlugs = array_keys(config('rbac.roles', []));
        $permissionSlugs = collect(config('rbac.permissions', []))
            ->pluck('slug')
            ->filter()
            ->values();

        $roleIds = DB::table('roles')
            ->whereIn('slug', $roleSlugs)
            ->pluck('id');

        $permissionIds = DB::table('permissions')
            ->whereIn('slug', $permissionSlugs)
            ->pluck('id');

        if (Schema::hasTable('role_user') && $roleIds->isNotEmpty()) {
            DB::table('role_user')->whereIn('role_id', $roleIds)->delete();
        }

        if (Schema::hasTable('permission_role') && $roleIds->isNotEmpty() && $permissionIds->isNotEmpty()) {
            DB::table('permission_role')
                ->whereIn('role_id', $roleIds)
                ->whereIn('permission_id', $permissionIds)
                ->delete();
        }

        DB::table('roles')->whereIn('slug', $roleSlugs)->delete();
        DB::table('permissions')->whereIn('slug', $permissionSlugs)->delete();
    }
};
