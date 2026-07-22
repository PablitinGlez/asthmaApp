<?php

namespace App\Filament\Resources\Users\Schemas;

use Filament\Forms\Components\DateTimePicker;
use Filament\Forms\Components\TextInput;
use Filament\Forms\Components\Toggle;
use Filament\Forms\Components\Select;
use Filament\Schemas\Components\Section;
use Filament\Schemas\Schema;
use Illuminate\Support\Facades\Hash;

class UserForm
{
    public static function configure(Schema $schema): Schema
    {
        return $schema
            ->components([
                Section::make('Información de Usuario')
                    ->columns(2)
                    ->schema([
                        TextInput::make('full_name')
                            ->label('Nombre Completo')
                            ->required(),
                        TextInput::make('email')
                            ->label('Correo Electrónico')
                            ->email()
                            ->required()
                            ->unique(ignoreRecord: true),
                        Select::make('role')
                            ->label('Rol del Sistema')
                            ->options([
                                'admin' => 'Administrador',
                                'doctor' => 'Doctor',
                                'patient' => 'Paciente',
                            ])
                            ->required(),
                        TextInput::make('supabase_uid')
                            ->label('Supabase ID')
                            ->disabled()
                            ->dehydrated(false),
                    ]),

                Section::make('Estado y Seguridad')
                    ->columns(2)
                    ->schema([
                        Toggle::make('is_active')
                            ->label('Cuenta Activa')
                            ->onColor('success'),
                        Toggle::make('email_verified')
                            ->label('Email Verificado')
                            ->onColor('success'),
                        TextInput::make('password')
                            ->label('Contraseña (Solo para cambiar)')
                            ->password()
                            ->dehydrateStateUsing(fn ($state) => Hash::make($state))
                            ->dehydrated(fn ($state) => filled($state))
                            ->required(fn (string $context): bool => $context === 'create'),
                    ]),

                Section::make('Personalización de Avatar')
                    ->columns(3)
                    ->collapsed()
                    ->schema([
                        TextInput::make('avatar_seed')
                            ->label('Semilla'),
                        TextInput::make('avatar_background')
                            ->label('Color Fondo (HEX)'),
                        TextInput::make('avatar_background_type')
                            ->label('Tipo Fondo'),
                    ]),
            ]);
    }
}
