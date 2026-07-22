import { Injectable, inject } from '@angular/core';
import { HttpClient, HttpHeaders } from '@angular/common/http';
import { environment } from '@env/environment';
import { AuthService } from './auth.service';
import { firstValueFrom } from 'rxjs';

@Injectable({
  providedIn: 'root'
})
export class DoctorService {
  private http = inject(HttpClient);
  private authService = inject(AuthService);
  private apiUrl = environment.apiUrl.replace('/api/admin', '');

  private async getHeaders(): Promise<HttpHeaders> {
    const sessionData = await this.authService['supabase'].auth.getSession();
    const token = sessionData?.data?.session?.access_token ?? null;
    return new HttpHeaders({ 'Authorization': `Bearer ${token}` });
  }

  // ── Perfil del doctor ────────────────────────────────────────────────────────
  async getMyProfile(): Promise<any> {
    const headers = await this.getHeaders();
    return firstValueFrom(this.http.get<any>(`${this.apiUrl}/api/doctor/profile`, { headers }));
  }

  // ── Listar pacientes ─────────────────────────────────────────────────────────
  async getMyPatients(search?: string, riskLevel?: string): Promise<any> {
    const headers = await this.getHeaders();
    let url = `${this.apiUrl}/api/patients?limit=100`;
    if (search) url += `&search=${encodeURIComponent(search)}`;
    if (riskLevel && riskLevel !== 'all') url += `&risk_level=${riskLevel}`;
    return firstValueFrom(this.http.get<any>(url, { headers }));
  }

  // ── Detalle completo de un paciente (para el formulario de edición) ───────────
  async getPatientFull(patientId: number): Promise<any> {
    const headers = await this.getHeaders();
    return firstValueFrom(this.http.get<any>(`${this.apiUrl}/api/patients/${patientId}/full`, { headers }));
  }

  // ── Crear paciente completo (flujo multi-paso) ────────────────────────────────
  async createPatient(data: any): Promise<any> {
    const headers = await this.getHeaders();
    return firstValueFrom(this.http.post<any>(`${this.apiUrl}/api/patients`, data, { headers }));
  }

  // ── Actualizar datos del paciente ─────────────────────────────────────────────
  async updatePatient(patientId: number, data: any): Promise<any> {
    const headers = await this.getHeaders();
    return firstValueFrom(this.http.patch<any>(`${this.apiUrl}/api/patients/${patientId}`, data, { headers }));
  }

  // ── Reemplazar medicamentos ───────────────────────────────────────────────────
  async replacePatientMedications(patientId: number, medications: any[]): Promise<any> {
    const headers = await this.getHeaders();
    return firstValueFrom(this.http.put<any>(`${this.apiUrl}/api/patients/${patientId}/medications`, medications, { headers }));
  }

  // ── Reemplazar plan de acción ─────────────────────────────────────────────────
  async replacePatientActionPlan(patientId: number, planName: string, steps: any[]): Promise<any> {
    const headers = await this.getHeaders();
    return firstValueFrom(this.http.put<any>(`${this.apiUrl}/api/patients/${patientId}/action-plan`, { plan_name: planName, steps }, { headers }));
  }

  // ── Desvincular paciente ──────────────────────────────────────────────────────
  async removePatient(patientId: number): Promise<void> {
    const headers = await this.getHeaders();
    return firstValueFrom(this.http.delete<any>(`${this.apiUrl}/api/patients/${patientId}`, { headers }));
  }
}
