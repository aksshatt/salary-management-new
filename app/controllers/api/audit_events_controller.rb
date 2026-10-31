module Api
  class AuditEventsController < BaseController
    PER_PAGE = 25
    TYPES = %w[Employee SalaryRevision PayrollEntry PayrollRun Country ExchangeRate].freeze

    def index
      events = AuditEvent.order(created_at: :desc, id: :desc)
      events = events.where(employee_id: params[:employee_id]) if params[:employee_id].present?
      events = events.where(auditable_type: params[:type]) if params[:type].in?(TYPES)
      page = [ params[:page].to_i, 1 ].max
      paged = events.limit(PER_PAGE).offset((page - 1) * PER_PAGE).includes(:employee, :auditable).to_a
      preload_payroll_months(paged)

      render json: { events: paged.map { |event| event_json(event) }, total: events.count, page:, per_page: PER_PAGE }
    end

    private
      # Payroll entry labels name their month; load those runs in one query.
      def preload_payroll_months(events)
        entries = events.map(&:auditable).grep(PayrollEntry)
        ActiveRecord::Associations::Preloader.new(records: entries, associations: :payroll_run).call
      end

      def event_json(event)
        {
          id: event.id, type: event.auditable_type, label: label(event), employee_id: event.employee_id,
          action: event.action, changes: event.field_changes, created_at: event.created_at
        }
      end

      def label(event)
        record = event.auditable
        case record
        when Employee then record.name
        when SalaryRevision then event.employee.name
        when PayrollEntry then "#{event.employee.name} (payroll #{record.payroll_run.month.strftime('%Y-%m')})"
        when PayrollRun then "Payroll #{record.month.strftime('%Y-%m')}"
        when Country then record.name
        when ExchangeRate then record.currency_code
        end
      end
  end
end
