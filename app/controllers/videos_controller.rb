require 'google/apis/youtube_v3'

class VideosController < ApplicationController
  before_action :set_youtube_service

  # 動画検索アクション
  def search
    query = params[:query]
    category_id = params[:category]

    if query.present?
      # YouTube APIの検索パラメータを設定
      search_params = {
        q: query,
        max_results: 12,
        type: 'video'
      }

      # カテゴリIDが指定されている場合は検索パラメータに追加
      search_params[:video_category_id] = category_id if category_id.present?

      begin
        # YouTube APIで動画を検索
        results = @youtube_service.list_searches('snippet', **search_params)

        # 検索結果を整形
        @videos = results.items.map do |item|
          video_id = item.id.video_id
          next unless video_id

          # 動画の統計情報を取得
          video_details = @youtube_service.list_videos('statistics', id: video_id).items.first
          next unless video_details

          {
            video_id: video_id,
            title: item.snippet.title,
            channel_title: item.snippet.channel_title,
            view_count: video_details.statistics.view_count,
            description: item.snippet.description,
            thumbnail: item.snippet.thumbnails.high.url,
            video_url: "https://www.youtube.com/watch?v=#{video_id}"
          }
        end.compact
      rescue Google::Apis::ClientError => e
        # エラー処理
        Rails.logger.error("YouTube API error: #{e.message}")
        flash[:alert] = "YouTube API error: #{e.message}"
        @videos = []
      end
    else
      @videos = []
    end
  end

  # 動画保存アクション
  def create
    # 必要なパラメータを許可
    video_data = params.require(:video).permit(:video_id, :title, :view_count, :description, :thumbnail, :video_url)

    # 動画情報を保存または更新
    video = Video.find_or_initialize_by(video_id: video_data[:video_id])
    if video.update(video_data)
      flash[:notice] = "Video saved successfully!"
      redirect_to videos_path
    else
      flash[:alert] = "Failed to save the video."
      redirect_to search_videos_path
    end
  end

  # 動画一覧表示アクション
  def index
    # 再生回数順に動画を表示
    @videos = Video.order(view_count: :desc).limit(10)
  end

  private

  # YouTube APIのサービス設定
  def set_youtube_service
    @youtube_service ||= Google::Apis::YoutubeV3::YouTubeService.new.tap do |service|
      service.key = ENV['YOUTUBE_API_KEY']
    end
  end
end
