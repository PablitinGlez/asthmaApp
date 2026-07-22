<?php

namespace App\Filament\Resources\Doctors\Schemas;

use Filament\Forms\Components\TextInput;
use Filament\Forms\Components\Textarea;
use Filament\Forms\Components\Select;
use Filament\Forms\Components\Toggle;
use Filament\Schemas\Components\Section;
use Filament\Schemas\Schema;

class DoctorForm
{
    public static function configure(Schema $schema): Schema
    {
        return $schema
            ->components([
                Section::make('Vinculación y Código')
                    ->columns(2)
                    ->schema([
                        Select::make('user_id')
                            ->label('Usuario (Doctor)')
                            ->relationship('user', 'full_name')
                            ->searchable()
                            ->required(),
                        TextInput::make('doctor_code')
                            ->label('Código Único')
                            ->disabled()
                            ->placeholder('Se genera automáticamente'),
                    ]),

                Section::make('Información Profesional')
                    ->columns(2)
                    ->schema([
                        TextInput::make('specialty')
                            ->label('Especialidad')
                            ->required(),
                        TextInput::make('license_number')
                            ->label('Cédula Profesional')
                            ->required(),
                        TextInput::make('hospital_name')
                            ->label('Hospital / Clínica'),
                        Toggle::make('is_verified')
                            ->label('Perfil Verificado')
                            ->onColor('success'),
                    ]),

                Section::make('Biografía')
                    ->schema([
                        Textarea::make('bio')
                            ->label('Resumen Profesional')
                            ->rows(3),
                    ]),
            ]);
    }
}
