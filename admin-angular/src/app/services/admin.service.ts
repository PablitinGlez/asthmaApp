import { Injectable, inject } from '@angular/core';
import { HttpClient, HttpHeaders } from '@angular/common/http';
import { AuthService } from './auth.service';
import { firstValueFrom } from 'rxjs';
import { environment } from '../../environments/environment';

@Injectable({
  providedIn: 'root'
})
export class AdminService {
  private http = inject(HttpClient);
  private authService = inject(AuthService);
  private apiUrl = environment.apiUrl; 

  async inviteDoctor(doctorData: any) {
    const payload = {
      ...doctorData,
      redirect_url: `${window.location.origin}/set-password` 
    };
    console.log('Enviando invitación a:', payload);
    return firstValueFrom(
      this.http.post(`${this.apiUrl}/invite-doctor`, payload, {
        headers: new HttpHeaders({
          'Content-Type': 'application/json',
          'X-Dashboard-API-Key': 'juanpi-secret-dashboard-key-2025' 
        })
      })
    );
  }

  async getDoctors() {
    return firstValueFrom(
      this.http.get<any[]>(`${this.apiUrl}/doctors`, {
        headers: new HttpHeaders({
          'X-Dashboard-API-Key': 'juanpi-secret-dashboard-key-2025'
        })
      })
    );
  }
}
