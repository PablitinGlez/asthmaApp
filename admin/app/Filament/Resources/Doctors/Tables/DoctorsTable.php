<?php

namespace App\Filament\Resources\Doctors\Tables;

use Filament\Actions\BulkActionGroup;
use Filament\Actions\DeleteBulkAction;
use Filament\Actions\EditAction;
use Filament\Tables\Columns\TextColumn;
use Filament\Tables\Table;

class DoctorsTable
{
    public static function configure(Table $table): Table
    {
        return $table
            ->columns([
                TextColumn::make('user.full_name')
                    ->label('Doctor')
                    ->searchable()
                    ->sortable(),
                TextColumn::make('doctor_code')
                    ->label('Código')
                    ->searchable()
                    ->sortable(),
                TextColumn::make('specialty')
                    ->label('Especialidad')
                    ->searchable(),
                TextColumn::make('license_number')
                    ->label('Cédula')
                    ->searchable(),
                \Filament\Tables\Columns\ToggleColumn::make('is_verified')
                    ->label('Verificado')
                    ->onColor('success'),
                TextColumn::make('created_at')
                    ->label('Registrado')
                    ->dateTime('d/m/Y')
                    ->sortable(),
            ])
            ->filters([
                \Filament\Tables\Filters\TernaryFilter::make('is_verified')
                    ->label('Estado de Verificación')
                    ->placeholder('Todos')
                    ->trueLabel('Verificados')
                    ->falseLabel('No Verificados'),
            ])
            ->recordActions([
                EditAction::make(),
            ])
            ->toolbarActions([
                BulkActionGroup::make([
                    DeleteBulkAction::make(),
                ]),
            ]);
    }
}
