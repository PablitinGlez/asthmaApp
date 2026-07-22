import { Component, inject, OnInit, ChangeDetectorRef } from '@angular/core';
import { CommonModule } from '@angular/common';
import { SidebarComponent } from '../../components/sidebar/sidebar.component';
import { DoctorService } from '../../services/doctor.service';
import { FormsModule } from '@angular/forms';

@Component({
  selector: 'app-patients',
  standalone: true,
  imports: [CommonModule, SidebarComponent, FormsModule],
  templateUrl: './patients.component.html',
  styleUrl: './patients.component.css'
})
export class PatientsComponent implements OnInit {
  private doctorService = inject(DoctorService);
  private cdr = inject(ChangeDetectorRef);

  // Lista
  patients: any[] = [];
  isLoading = true;

  // Panel de edición
  selectedPatient: any = null;
  fullPatientData: any = null;
  showDetailsPanel = false;
  isSaving = false;
  activeTab: 'basic' | 'clinical' | 'medications' | 'plan' = 'basic';

  // Formulario de edición
  editBasic: any = {};
  editClinical: any = {};
  editMedications: any[] = [];
  editActionPlan: any = { plan_name: '', steps: [] };

  // Modal de creación (multi-paso)
  showCreateModal = false;
  createStep = 1;
  totalSteps = 5;
  isCreating = false;
  createForm: any = {
    // Paso 1
    email: '', first_name: '', last_name: '',
    // Paso 2
    age: null, gender: '', phone_number: '',
    address_street: '', address_city: '', address_state: '', address_zip: '',
    health_insurance_number: '',
    // Paso 3
    height_cm: null, weight_kg: null, blood_type: '',
    asthma_type: '', diagnosis_date: '', known_allergies: '', personal_best_pef: null,
    // Paso 4
    action_plan_name: '', action_steps: [],
    // Paso 5
    medications: []
  };

  // Temp para añadir items al wizard
  newStep = { step_order: 1, step_title: '', step_description: '', is_critical: false };
  newMed = { name: '', dosage: '', frequency_hours: null as number | null, next_dose: '' };

  async ngOnInit() {
    await this.loadPatients();
  }

  async loadPatients() {
    try {
      this.isLoading = true;
      const res = await this.doctorService.getMyPatients();
      this.patients = res.data || res || [];
    } catch (e) {
      console.error('Error al cargar pacientes:', e);
    } finally {
      this.isLoading = false;
      this.cdr.detectChanges();
    }
  }

  // ─────────────────────────── PANEL DE DETALLES ───────────────────────────────

  async openDetails(patient: any) {
    this.selectedPatient = patient;
    this.activeTab = 'basic';
    this.showDetailsPanel = true;

    try {
      this.fullPatientData = await this.doctorService.getPatientFull(patient.id);
      console.log('✅ Datos completos cargados:', this.fullPatientData);
      this.loadEditForms();
    } catch (e: any) {
      console.error('❌ Error cargando datos completos de GET /api/patients/ID/full. Cayendo al objeto resumen:', e);
      if (e.error) console.error('Detalle del error:', e.error);
      this.fullPatientData = patient;
      this.loadEditForms();
    }
    this.cdr.detectChanges();
  }

  loadEditForms() {
    const d = this.fullPatientData;
    this.editBasic = {
      first_name: d.first_name || '',
      last_name: d.last_name || '',
      age: d.age || null,
      gender: d.gender || '',
      phone_number: d.phone_number || '',
      address_street: d.address_street || '',
      address_city: d.address_city || '',
      address_state: d.address_state || '',
      address_zip: d.address_zip || '',
      health_insurance_number: d.health_insurance_number || '',
    };
    this.editClinical = {
      asthma_type: d.asthma_type || '',
      height_cm: d.height_cm || null,
      weight_kg: d.weight_kg || null,
      blood_type: d.blood_type || '',
      known_allergies: d.known_allergies || '',
      personal_best_pef: d.personal_best_pef || null,
      diagnosis_date: d.diagnosis_date || '',
    };
    this.editMedications = (d.medications || []).map((m: any) => ({ ...m }));
    if (d.action_plan) {
      this.editActionPlan = {
        plan_name: d.action_plan.plan_name || '',
        steps: (d.action_plan.steps || []).map((s: any) => ({ ...s }))
      };
    } else {
      this.editActionPlan = { plan_name: '', steps: [] };
    }
  }

  closeDetails() {
    this.showDetailsPanel = false;
    setTimeout(() => {
      this.selectedPatient = null;
      this.fullPatientData = null;
    }, 300);
  }

  setTab(tab: 'basic' | 'clinical' | 'medications' | 'plan') {
    this.activeTab = tab;
  }

  // ─────────────────────────── GUARDAR CAMBIOS ─────────────────────────────────

  async saveCurrentTab() {
    if (this.isSaving) return;
    this.isSaving = true;
    try {
      const id = this.selectedPatient.id;
      if (this.activeTab === 'basic') {
        await this.doctorService.updatePatient(id, this.editBasic);
      } else if (this.activeTab === 'clinical') {
        await this.doctorService.updatePatient(id, this.editClinical);
      } else if (this.activeTab === 'medications') {
        await this.doctorService.replacePatientMedications(id, this.editMedications);
      } else if (this.activeTab === 'plan') {
        await this.doctorService.replacePatientActionPlan(id, this.editActionPlan.plan_name, this.editActionPlan.steps);
      }
      alert('✅ Datos actualizados correctamente');
      await this.loadPatients();
    } catch (e: any) {
      alert('❌ Error: ' + (e.error?.detail || 'No se pudo actualizar'));
    } finally {
      this.isSaving = false;
      this.cdr.detectChanges();
    }
  }

  // Medicamentos en edición
  addEditMed() {
    this.editMedications.push({ name: '', dosage: '', frequency_hours: null, next_dose: null });
  }
  removeEditMed(i: number) {
    this.editMedications.splice(i, 1);
  }

  // Pasos en edición
  addEditStep() {
    const order = (this.editActionPlan.steps.length || 0) + 1;
    this.editActionPlan.steps.push({ step_order: order, step_title: '', step_description: '', is_critical: false });
  }
  removeEditStep(i: number) {
    this.editActionPlan.steps.splice(i, 1);
  }

  // ─────────────────────────── MODAL DE CREACIÓN ───────────────────────────────

  openCreateModal() {
    this.showCreateModal = true;
    this.createStep = 1;
    this.createForm = {
      email: '', first_name: '', last_name: '',
      age: null, gender: '', phone_number: '',
      address_street: '', address_city: '', address_state: '', address_zip: '',
      health_insurance_number: '',
      height_cm: null, weight_kg: null, blood_type: '',
      asthma_type: '', diagnosis_date: '', known_allergies: '', personal_best_pef: null,
      action_plan_name: '', action_steps: [],
      medications: []
    };
  }

  closeCreateModal() {
    this.showCreateModal = false;
    this.createStep = 1;
  }

  nextStep() {
    if (this.createStep < this.totalSteps) this.createStep++;
  }

  prevStep() {
    if (this.createStep > 1) this.createStep--;
  }

  addWizardMed() {
    if (!this.newMed.name) return;
    this.createForm.medications.push({
      name: this.newMed.name,
      dosage: this.newMed.dosage || null,
      frequency_hours: this.newMed.frequency_hours ? Number(this.newMed.frequency_hours) : null,
      next_dose: this.newMed.next_dose ? new Date(this.newMed.next_dose).toISOString() : null,
    });
    this.newMed = { name: '', dosage: '', frequency_hours: null, next_dose: '' };
  }

  removeWizardMed(i: number) {
    this.createForm.medications.splice(i, 1);
  }

  addWizardStep() {
    if (!this.newStep.step_title) return;
    this.createForm.action_steps.push({ ...this.newStep });
    this.newStep = {
      step_order: this.createForm.action_steps.length + 1,
      step_title: '', step_description: '', is_critical: false
    };
  }

  removeWizardStep(i: number) {
    this.createForm.action_steps.splice(i, 1);
  }

  async submitCreate() {
    if (this.isCreating) return;
    this.isCreating = true;

    // Auto-guardar si el usuario llenó campos pero olvidó presionar "+"
    if (this.newMed.name) this.addWizardMed();
    if (this.newStep.step_title) this.addWizardStep();

    try {
      const payload: any = {
        email: this.createForm.email,
        first_name: this.createForm.first_name,
        last_name: this.createForm.last_name,
      };
      if (this.createForm.age) payload.age = Number(this.createForm.age);
      if (this.createForm.gender) payload.gender = this.createForm.gender;
      if (this.createForm.phone_number) payload.phone_number = this.createForm.phone_number;
      if (this.createForm.address_street) payload.address_street = this.createForm.address_street;
      if (this.createForm.address_city) payload.address_city = this.createForm.address_city;
      if (this.createForm.address_state) payload.address_state = this.createForm.address_state;
      if (this.createForm.address_zip) payload.address_zip = this.createForm.address_zip;
      if (this.createForm.health_insurance_number) payload.health_insurance_number = this.createForm.health_insurance_number;
      if (this.createForm.height_cm) payload.height_cm = Number(this.createForm.height_cm);
      if (this.createForm.weight_kg) payload.weight_kg = Number(this.createForm.weight_kg);
      if (this.createForm.asthma_type) payload.asthma_type = this.createForm.asthma_type;
      if (this.createForm.blood_type) payload.blood_type = this.createForm.blood_type;
      if (this.createForm.known_allergies) payload.known_allergies = this.createForm.known_allergies;
      if (this.createForm.personal_best_pef) payload.personal_best_pef = Number(this.createForm.personal_best_pef);
      if (this.createForm.diagnosis_date) payload.diagnosis_date = this.createForm.diagnosis_date;
      if (this.createForm.action_plan_name) {
        payload.action_plan_name = this.createForm.action_plan_name;
        payload.action_steps = this.createForm.action_steps;
      }
      if (this.createForm.medications.length > 0) {
        payload.medications = this.createForm.medications;
      }

      console.log('📤 Payload enviado a la API:', JSON.stringify(payload, null, 2));
      const res = await this.doctorService.createPatient(payload);
      alert(`✅ Paciente creado. Se envió invitación al email: ${res.email}`);
      this.closeCreateModal();
      await this.loadPatients();
    } catch (e: any) {
      const detail = e.error?.detail;
      const msg = Array.isArray(detail)
        ? detail.map((d: any) => `${(d.loc || []).slice(-1)[0]}: ${d.msg}`).join('\n')
        : (typeof detail === 'string' ? detail : JSON.stringify(detail) || 'No se pudo crear el paciente');
      alert('❌ Error de validación:\n' + msg);
    } finally {
      this.isCreating = false;
      this.cdr.detectChanges();
    }
  }

  getRiskBadge(level: string): { bg: string; color: string; label: string } {
    switch (level) {
      case 'high': return { bg: '#fee2e2', color: '#991b1b', label: 'Alto' };
      case 'moderate': return { bg: '#fef3c7', color: '#92400e', label: 'Moderado' };
      default: return { bg: '#d1fae5', color: '#065f46', label: 'Estable' };
    }
  }
}
