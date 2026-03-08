<?php

namespace App\Http\Requests\Appointments;

use App\Models\Appointment;
use Illuminate\Foundation\Http\FormRequest;
use Illuminate\Validation\Rule;

abstract class AppointmentUpsertRequest extends FormRequest
{
    public const STATUSES = [
        'booked',
        'confirmed',
        'arrived',
        'in_consult',
        'completed',
        'cancelled',
        'no_show',
    ];

    public const BOOKING_TYPES = [
        'new_patient',
        'returning_patient',
    ];

    public const CHANNELS = [
        'in_person',
        'mobile',
        'web',
        'admin_capture',
    ];

    public function authorize(): bool
    {
        return true;
    }

    /**
     * @return array<string, mixed>
     */
    protected function appointmentRules(bool $updating = false): array
    {
        $requiredIfCreating = $updating ? ['sometimes'] : ['required'];
        $patientIdRules = ['nullable', 'uuid', 'exists:patients,id'];
        $patientPayloadRules = ['nullable', 'array'];

        if (! $updating) {
            $patientIdRules[] = 'required_without:patient';
            $patientPayloadRules[] = 'required_without:patient_id';
        }

        $appointment = $this->route('appointment');
        $appointmentId = $appointment instanceof Appointment
            ? $appointment->id
            : $this->route('appointmentId');

        return [
            'id' => ['sometimes', 'uuid'],
            'clinic_id' => ['nullable', 'uuid', 'exists:clinics,id'],
            'patient_id' => $patientIdRules,
            'provider_id' => ['nullable', 'uuid', 'exists:providers,id'],
            'booking_type' => array_merge($requiredIfCreating, ['nullable', Rule::in(self::BOOKING_TYPES)]),
            'status' => ['sometimes', Rule::in(self::STATUSES)],
            'scheduled_for' => array_merge($requiredIfCreating, ['date']),
            'duration_minutes' => ['sometimes', 'integer', 'min:10', 'max:240'],
            'reason_for_visit' => ['nullable', 'string', 'max:255'],
            'notes' => ['nullable', 'string'],
            'booking_channel' => ['sometimes', Rule::in(self::CHANNELS)],
            'cancellation_reason' => ['nullable', 'string'],
            'metadata' => ['nullable', 'array'],
            'patient' => $patientPayloadRules,
            'patient.medical_record_number' => ['nullable', 'string', 'max:255'],
            'patient.title' => ['nullable', 'string', 'max:32'],
            'patient.first_name' => ['required_with:patient', 'string', 'max:255'],
            'patient.middle_name' => ['nullable', 'string', 'max:255'],
            'patient.last_name' => ['required_with:patient', 'string', 'max:255'],
            'patient.preferred_name' => ['nullable', 'string', 'max:255'],
            'patient.date_of_birth' => ['nullable', 'date'],
            'patient.sex' => ['nullable', 'string', 'max:32'],
            'patient.phone' => ['nullable', 'string', 'max:255'],
            'patient.alternate_phone' => ['nullable', 'string', 'max:255'],
            'patient.email' => ['nullable', 'email', 'max:255'],
            'patient.national_id_number' => ['nullable', 'string', 'max:255'],
            'patient.passport_number' => ['nullable', 'string', 'max:255'],
            'patient.external_reference' => ['nullable', 'string', 'max:255'],
            'patient.address_line_1' => ['nullable', 'string', 'max:255'],
            'patient.address_line_2' => ['nullable', 'string', 'max:255'],
            'patient.city' => ['nullable', 'string', 'max:255'],
            'patient.province' => ['nullable', 'string', 'max:255'],
            'patient.postal_code' => ['nullable', 'string', 'max:32'],
            'patient.country' => ['nullable', 'string', 'size:2'],
            'patient.emergency_contact_name' => ['nullable', 'string', 'max:255'],
            'patient.emergency_contact_phone' => ['nullable', 'string', 'max:255'],
            'patient.notes' => ['nullable', 'string'],
        ];
    }
}
