class AddVideoUrlToVideos < ActiveRecord::Migration[7.1]
  def change
    add_column :videos, :video_url, :string
  end
end
