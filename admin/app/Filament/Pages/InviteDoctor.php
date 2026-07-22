<?php

namespace App\Filament\Pages;

use Filament\Forms\Components\TextInput;
use Filament\Schemas\Components\Section;
use Filament\Schemas\Schema;
use Filament\Pages\Page;
use Filament\Actions\Action;
use Filament\Notifications\Notification;
use Illuminate\Support\Facades\Http;

class InviteDoctor extends Page
{
    protected static string|\BackedEnum|null $navigationIcon = 'heroicon-o-paper-airplane';

    protected string $view = 'filament.pages.invite-doctor';

    protected static ?string $title = 'Invitar Nuevo Doctor';

    protected static ?string $navigationLabel = 'Invitar Doctor';

    protected static string|\UnitEnum|null $navigationGroup = 'Gestión';

    public ?array $data = [];

    public function mount(): void
    {
        $this->data = [];
    }

    public function form(Schema $schema): Schema
    {
        return $schema
            ->components([
                Section::make('Datos de la Invitación')
                    ->description('Al enviar, se creará el usuario y se enviará un correo de bienvenida.')
                    ->columns(2)
                    ->schema([
                        TextInput::make('full_name')
                            ->label('Nombre Completo')
                            ->placeholder('Ej: Dr. Juan Pérez')
                            ->required(),
                        TextInput::make('email')
                            ->label('Correo Electrónico')
                            ->email()
                            ->placeholder('doctor@ejemplo.com')
                            ->required(),
                        TextInput::make('specialty')
                            ->label('Especialidad')
                            ->placeholder('Ej: Neumología Pediátrica')
                            ->required(),
                        TextInput::make('license_number')
                            ->label('Cédula Profesional')
                            ->placeholder('Ej: 12345678')
                            ->required(),
                        TextInput::make('hospital_name')
                            ->label('Hospital / Clínica')
                            ->placeholder('Ej: Hospital Ángeles'),
                    ])
            ])
            ->statePath('data');
    }

    protected function getHeaderActions(): array
    {
        return [
            Action::make('invite')
                ->label('Enviar Invitación 🚀')
                ->color('primary')
                ->action(function () {
                    $this->invite();
                }),
        ];
    }

    public function invite(): void
    {
        $input = $this->data;

        \Log::info('--- INICIANDO INVITACIÓN DE DOCTOR ---');
        \Log::info('Datos ingresados:', $input);

        if (empty($input['full_name']) || empty($input['email']) || empty($input['specialty']) || empty($input['license_number'])) {
            \Log::warning('Validación falló: Faltan campos requeridos.');
            Notification::make()
                ->danger()
                ->title('Campos requeridos')
                ->body('Por favor completa todos los campos obligatorios.')
                ->send();
            return;
        }

        try {
            $apiUrl = env('BACKEND_API_URL') . '/invite-doctor';
            $apiKey = env('DASHBOARD_API_KEY');

            \Log::info("Enviando petición a: {$apiUrl}");
            \Log::info("Con API Key: " . substr($apiKey, 0, 5) . '***');

            $response = Http::withHeaders([
                'X-Dashboard-API-Key' => $apiKey,
            ])->timeout(15)->post($apiUrl, [
                'email'          => $input['email'],
                'full_name'      => $input['full_name'],
                'specialty'      => $input['specialty'],
                'license_number' => $input['license_number'],
                'hospital_name'  => $input['hospital_name'] ?? null,
                'redirect_url'   => route('filament.admin.auth.login'),
            ]);

            \Log::info('Status HTTP de la API: ' . $response->status());
            \Log::info('Respuesta cruda de la API: ' . $response->body());

            if ($response->successful()) {
                Notification::make()
                    ->success()
                    ->title('¡Invitación Enviada!')
                    ->body("Se ha enviado el correo al Dr. {$input['full_name']} exitosamente.")
                    ->send();

                $this->data = [];
            } else {
                $detail = $response->json('detail');
                $errorMessage = is_array($detail) ? json_encode($detail) : ($detail ?? 'Error inesperado en la API.');
                
                \Log::error('La API devolvió un error: ' . $errorMessage);

                Notification::make()
                    ->danger()
                    ->title('Error de API')
                    ->body((string) $errorMessage)
                    ->send();
            }
        } catch (\Exception $e) {
            \Log::error('Excepción CRÍTICA capturada en Catch: ' . $e->getMessage());
            \Log::error('Trace: ' . $e->getTraceAsString());

            Notification::make()
                ->danger()
                ->title('Error de Conexión')
                ->body('No se pudo contactar con la API: ' . $e->getMessage())
                ->send();
        }
    }
}
