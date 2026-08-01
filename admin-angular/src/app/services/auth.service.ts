import { Injectable } from '@angular/core';
import { createClient, SupabaseClient, User } from '@supabase/supabase-js';
import { environment } from '@env/environment';
import { BehaviorSubject, Observable } from 'rxjs';

@Injectable({
  providedIn: 'root'
})
export class AuthService {
  private supabase: SupabaseClient;
  private currentUserSubject = new BehaviorSubject<User | null>(null);
  private currentUserRoleSubject = new BehaviorSubject<string | null>(null);

  constructor() {
    this.supabase = createClient(environment.supabaseUrl, environment.supabaseKey);
    
    // Escuchar cambios de autenticación sin bloquear Supabase
    this.supabase.auth.onAuthStateChange((event, session) => {
      console.log('Auth event:', event);
      this.currentUserSubject.next(session?.user ?? null);
      if (session?.user) {
        // Ejecutamos en segundo plano
        this.getUserRole(session.user.id).then(role => {
          this.currentUserRoleSubject.next(role);
        });
      } else {
        this.currentUserRoleSubject.next(null);
      }
    });
  }

  // Permite al Guard esperar la sesión real en vez del BehaviorSubject inicial (null)
  async getSession() {
    const { data: { session } } = await this.supabase.auth.getSession();
    this.currentUserSubject.next(session?.user ?? null);
    if (session?.user) {
      const role = await this.getUserRole(session.user.id);
      this.currentUserRoleSubject.next(role);
    } else {
      this.currentUserRoleSubject.next(null);
    }
    return session?.user ?? null;
  }

  get currentUser$(): Observable<User | null> {
    return this.currentUserSubject.asObservable();
  }

  get currentUserRole$(): Observable<string | null> {
    return this.currentUserRoleSubject.asObservable();
  }

  get currentUserValue(): User | null {
    return this.currentUserSubject.value;
  }

  async login(email: string, password: string) {
    const { data, error } = await this.supabase.auth.signInWithPassword({
      email,
      password
    });
    
    if (error) throw error;
    return data;
  }

  async logout() {
    await this.supabase.auth.signOut();
  }

  async getUserRole(uid: string) {
    const { data, error } = await this.supabase
      .from('users')
      .select('role')
      .eq('supabase_uid', uid)
      .single();
    
    if (error) return null;
    return data?.role;
  }

  async updatePassword(password: string) {
    const { data, error } = await this.supabase.auth.updateUser({
      password: password
    });
    if (error) throw error;
    return data;
  }
}
