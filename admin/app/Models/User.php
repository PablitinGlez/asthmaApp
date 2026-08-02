<?php

namespace App\Models;

use Database\Factories\UserFactory;
use Illuminate\Database\Eloquent\Factories\HasFactory;
use Filament\Models\Contracts\FilamentUser;
use Filament\Models\Contracts\HasName;
use Filament\Panel;
use Illuminate\Foundation\Auth\User as Authenticatable;
use Illuminate\Notifications\Notifiable;

class User extends Authenticatable implements FilamentUser, HasName
{
    
    use HasFactory, Notifiable;

    

    public function getFilamentName(): string
    {
        return $this->full_name ?? $this->email;
    }

    

    public function canAccessPanel(Panel $panel): bool
    {
        return $this->role === 'admin' && $this->is_active;
    }

    protected $table = 'users';

    

    protected $fillable = [
        'supabase_uid',
        'email',
        'full_name',
        'role',
        'is_active',
        'avatar_seed',
        'avatar_background',
        'password',
    ];

    

    protected $hidden = [
        'password',
        'remember_token',
    ];

    

    public function doctorProfile()
    {
        return $this->hasOne(Doctor::class, 'user_id');
    }

    

    public function patients()
    {
        return $this->belongsToMany(User::class, 'doctor_patients', 'doctor_id', 'patient_id');
    }

    

    public function doctors()
    {
        return $this->belongsToMany(User::class, 'doctor_patients', 'patient_id', 'doctor_id');
    }

    

    protected function casts(): array
    {
        return [
            'email_verified_at' => 'datetime',
            'is_active' => 'boolean',
            'password' => 'hashed',
        ];
    }
}
