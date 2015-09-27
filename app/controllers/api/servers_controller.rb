module Api
  class ServersController < ApplicationController
    respond_to :json

    def update
      # Unauthenticated users can't update.
      unless current_user
        head :forbidden
        return
      end
      server = Server.find(params[:id])
      server.update(server_params)
      if server.save
        respond_with server, location: api_servers_path
      else
        respond_with server, status: 422
      end
    end

    def destroy
      # Unauthenticated users can't delete.
      unless current_user
        head :forbidden
        return
      end
      server = Server.find(params[:id])
      server.destroy

      respond_with server, location: api_servers_path
    end

    def conformance
      server = Server.find(params[:id])
      conformance = server.load_conformance
      render json: {conformance: conformance}
    end

    def summary
      render json: {summary:Summary.where(server_id: params[:id]).try(:last)}
    end

    def generate_summary
      test_run = TestRun.find(params[:test_run_id])
      server = Server.find(params[:id])

      Aggregate.update(server, test_run)
      compliance = Aggregate.get_compliance(server)

      summary = Summary.new(
        server_id: server.id,
        test_run: test_run,
        compliance: compliance,
        generated_at: Time.now
      )


      server.summary = summary
      server.percent_passing = (compliance['passed'].to_f / (compliance['total'].to_f || 1)) * 100.0
      summary.save!
      server.save!

      render json: {summary: summary}
    end

    private

    def server_params
      params.require(:server).permit(:url, :name)
    end
  end
end
