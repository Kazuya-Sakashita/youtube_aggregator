require 'google/apis/youtube_v3'

class VideosController < ApplicationController
  before_action :set_youtube_service

  def search
    if params[:query].present?
      # YouTube APIのリクエストに並び替えオプション(order: 'viewCount')を追加
      results = @youtube_service.list_searches('snippet', q: params[:query], max_results: 10, order: 'viewCount')
      @videos = results.items.map do |item|
        video_id = item.id.video_id
        next unless video_id

        video_details = @youtube_service.list_videos('statistics', id: video_id).items.first
        next unless video_details

        {
          video_id: video_id,
          title: item.snippet.title,
          description: item.snippet.description,
          thumbnail: item.snippet.thumbnails.high.url,
          view_count: video_details.statistics.view_count
        }
      end.compact
    else
      @videos = []
    end
  rescue Google::Apis::ClientError => e
    Rails.logger.error("YouTube API error: #{e.message}")
    flash[:alert] = "YouTube API error: #{e.message}"
    @videos = []
  end



  def create
    # 必要なパラメータを許可
    video_data = params.require(:video).permit(:video_id, :title, :view_count, :description, :thumbnail)

    # 動画情報を保存または更新
    video = Video.find_or_initialize_by(video_id: video_data[:video_id])
    video.update(video_data)

    if video.persisted?
      flash[:notice] = "Video saved successfully!"
      redirect_to videos_path
    else
      flash[:alert] = "Failed to save the video."
      redirect_to search_videos_path
    end
  end


  def index
    @videos = Video.order(view_count: :desc).limit(10)
  end

  private

  def set_youtube_service
    @youtube_service ||= Google::Apis::YoutubeV3::YouTubeService.new.tap do |service|
      service.key = ENV['YOUTUBE_API_KEY']
    end
  end
end
