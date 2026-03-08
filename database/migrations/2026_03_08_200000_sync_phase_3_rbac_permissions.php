<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Support\Arr;
use Illuminate\Support\Facades\DB;
use Illuminate\Support\Facades\Schema;

return new class extends Migration
{
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
    }

    public function down(): void
    {
        if (! Schema::hasTable('roles') || ! Schema::hasTable('permissions')) {
            return;
        }

        $permissionSlugs = collect(config('rbac.permissions', []))
            ->pluck('slug')
            ->filter()
            ->values();

        $phaseThreeSlugs = $permissionSlugs->filter(
            fn (string $slug): bool => str_starts_with($slug, 'appointments.')
                || str_starts_with($slug, 'onboarding.')
                || str_starts_with($slug, 'consents.'),
        );

        if ($phaseThreeSlugs->isEmpty()) {
            return;
        }

        $permissionIds = DB::table('permissions')
            ->whereIn('slug', $phaseThreeSlugs)
            ->pluck('id');

        if (Schema::hasTable('permission_role') && $permissionIds->isNotEmpty()) {
            DB::table('permission_role')
                ->whereIn('permission_id', $permissionIds)
                ->delete();
        }

        DB::table('permissions')->whereIn('slug', $phaseThreeSlugs)->delete();
    }
};
