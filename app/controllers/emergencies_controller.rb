class EmergenciesController < ApplicationController
  before_action :find_emergency, only: [:show, :update]

  def index
    @emergencies = Emergency.all
    @response_count = Response.response_count

    render json: { emergencies: [] } if @emergencies.empty?
  end

  def create
    @emergency = Emergency.new(create_emergency_params)

    return render json: { message: @emergency.errors.messages }, status: 422 unless @emergency.save

    Dispatcher.dispatch_responders(@emergency)
    @full_response = Response.response_message(@emergency)
    @responder_names = @emergency.responders.pluck(:name)

    render :show, status: 201
  end

  def show
    render json: {}, status: 404 unless @emergency
  end

  def update
    if @emergency.update(update_emergency_params)
      Emergency.resolve_emergency(@emergency) if @emergency.resolved_at?
      render :show
    else
      @errors = @emergency.errors.messages
      render json: { message: @errors }, status: 422
    end
  end

  private

    def create_emergency_params
      params.require(:emergency).permit(:code, :fire_severity, :police_severity, :medical_severity)
    end

    def update_emergency_params
      params.require(:emergency).permit(:fire_severity, :police_severity, :medical_severity, :resolved_at)
    end

    def find_emergency
      @emergency = Emergency.find_by(code: params[:id])
    end
end
