<?php

namespace Database\Seeders;

use Illuminate\Database\Seeder;
use Illuminate\Support\Arr;
use Illuminate\Support\Facades\DB;
use Illuminate\Support\Facades\Schema;

class Phase4RbacSeeder extends Seeder
{
    /**
     * Run the database seeds.
     */
    public function run(): void
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

        if (! Schema::hasTable('permission_role')) {
            return;
        }

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

        if ($permissionPivot !== []) {
            DB::table('permission_role')->upsert(
                $permissionPivot,
                ['permission_id', 'role_id'],
                ['updated_at'],
            );
        }
    }
}