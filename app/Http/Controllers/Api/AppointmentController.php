<?php

namespace App\Http\Controllers\Api;

use App\Http\Controllers\Controller;
use App\Http\Requests\Appointments\ListAppointmentsRequest;
use App\Http\Requests\Appointments\StoreAppointmentRequest;
use App\Http\Requests\Appointments\UpdateAppointmentRequest;
use App\Http\Resources\Appointments\AppointmentResource;
use App\Models\Appointment;
use App\Models\Patient;
use App\Services\AppointmentService;
use App\Support\ClinicalAudit;
use Illuminate\Http\JsonResponse;
use Illuminate\Http\Request;
use Illuminate\Http\Resources\Json\AnonymousResourceCollection;

class AppointmentController extends Controller
{
    public function __construct(
        private readonly AppointmentService $appointments,
    ) {
    }

    public function index(ListAppointmentsRequest $request): AnonymousResourceCollection
    {
        $this->authorize('viewAny', Appointment::class);

        /** @var \App\Models\User $user */
        $user = $request->user();
        $appointments = $this->appointments->list(
            $user,
            $request->validated(),
            $request->integer('per_page', 25),
        );

        ClinicalAudit::record(
            request: $request,
            event: 'appointments.listed',
            context: [
                'filters' => $request->validated(),
                'results_count' => $appointments->count(),
            ],
        );

        return AppointmentResource::collection($appointments);
    }

    public function store(StoreAppointmentRequest $request): JsonResponse
    {
        $this->authorize('create', Appointment::class);

        /** @var \App\Models\User $user */
        $user = $request->user();
        $appointment = $this->appointments->create($user, $request->validated());

        ClinicalAudit::record(
            request: $request,
            event: 'appointment.created',
            auditable: $appointment,
            patientId: $appointment->patient_id,
        );

        return (new AppointmentResource($appointment))
            ->response()
            ->setStatusCode(201);
    }

    public function show(Request $request, Appointment $appointment): AppointmentResource
    {
        $this->authorize('view', $appointment);

        /** @var \App\Models\User $user */
        $user = $request->user();
        $appointment = $this->appointments->detail($user, $appointment);

        ClinicalAudit::record(
            request: $request,
            event: 'appointment.viewed',
            auditable: $appointment,
            patientId: $appointment->patient_id,
        );

        return new AppointmentResource($appointment);
    }

    public function update(UpdateAppointmentRequest $request, Appointment $appointment): JsonResponse
    {
        $this->authorize('update', $appointment);

        /** @var \App\Models\User $user */
        $user = $request->user();
        $appointment = $this->appointments->update($user, $appointment, $request->validated());

        ClinicalAudit::record(
            request: $request,
            event: 'appointment.updated',
            auditable: $appointment,
            patientId: $appointment->patient_id,
        );

        return (new AppointmentResource($appointment))->response();
    }

    public function patientAppointments(Request $request, Patient $patient): AnonymousResourceCollection
    {
        $this->authorize('view', $patient);
        $this->authorize('viewAny', Appointment::class);

        /** @var \App\Models\User $user */
        $user = $request->user();
        $appointments = $this->appointments->patientAppointments($user, $patient);

        ClinicalAudit::record(
            request: $request,
            event: 'patient.appointments.viewed',
            auditable: $patient,
            context: [
                'count' => $appointments->count(),
            ],
            patientId: $patient->id,
        );

        return AppointmentResource::collection($appointments)->additional([
            'meta' => [
                'patient_id' => $patient->id,
                'count' => $appointments->count(),
            ],
        ]);
    }
}
