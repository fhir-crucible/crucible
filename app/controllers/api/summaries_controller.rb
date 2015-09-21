module Api
  class SummariesController < ApplicationController
    respond_to :json

    def index
        render json: Summary.all.only(:_id)
    end

    def show
      # TODO: fix this... currently this is server id instead of summary
      summary = Summary.where({server_id: params[:summary_id]}).desc(:generated_at).first
      #fresh_when(etag: summary, last_modified: summary.generated_at, public: true)
      #summary = Summary.where(_id: params[:summary_id]).try(:last)
      unless params[:issues]
        summary.compliance = Compliance.remove_compliance_fields(summary.compliance, ['issues'])
      end
      render json: {summary: summary}
    end

    def index_latest
      # find summaries ordered by generated_at and then return the unique ones
      # summaries = Summary.desc(:generated_at).uniq(&:server_id)
      sums = Summary.only(:_id, :server_id).desc(:_id).uniq(&:server_id)
      summaries = {
        _id: Time.now.to_i,
        summaries: sums.map(&:id)
      }
      render json: {aggregateSummary: summaries}
    end

    def show_latest
      summary = Summary.where(server_id: params[:server_id]).try(:last)
      render json: {summary: summary}
    end

    private

    def server_params
      params.require(:summary).permit(:compliance, :generated_at)
    end
  end
end
