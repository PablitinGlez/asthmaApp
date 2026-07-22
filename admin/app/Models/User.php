<?php

namespace App\Models;

// use Illuminate\Contracts\Auth\MustVerifyEmail;
use Database\Factories\UserFactory;
use Illuminate\Database\Eloquent\Factories\HasFactory;
use Filament\Models\Contracts\FilamentUser;
use Filament\Models\Contracts\HasName;
use Filament\Panel;
use Illuminate\Foundation\Auth\User as Authenticatable;
use Illuminate\Notifications\Notifiable;

class User extends Authenticatable implements FilamentUser, HasName
{
    /** @use HasFactory<UserFactory> */
    use HasFactory, Notifiable;

    /**
     * Get the name of the user for Filament.
     */
    public function getFilamentName(): string
    {
        return $this->full_name ?? $this->email;
    }

    /**
     * Determine if the user can access the Filament panel.
     */
    public function canAccessPanel(Panel $panel): bool
    {
        return $this->role === 'admin' && $this->is_active;
    }

    protected $table = 'users';

    /**
     * The attributes that are mass assignable.
     *
     * @var list<string>
     */
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

    /**
     * The attributes that should be hidden for serialization.
     *
     * @var list<string>
     */
    protected $hidden = [
        'password',
        'remember_token',
    ];

    /**
     * Get the doctor profile associated with the user.
     */
    public function doctorProfile()
    {
        return $this->hasOne(Doctor::class, 'user_id');
    }

    /**
     * Patients assigned to this doctor (if user is a doctor).
     */
    public function patients()
    {
        return $this->belongsToMany(User::class, 'doctor_patients', 'doctor_id', 'patient_id');
    }

    /**
     * Doctors assigned to this patient (if user is a patient).
     */
    public function doctors()
    {
        return $this->belongsToMany(User::class, 'doctor_patients', 'patient_id', 'doctor_id');
    }

    /**
     * Get the attributes that should be cast.
     *
     * @return array<string, string>
     */
    protected function casts(): array
    {
        return [
            'email_verified_at' => 'datetime',
            'is_active' => 'boolean',
            'password' => 'hashed',
        ];
    }
}
