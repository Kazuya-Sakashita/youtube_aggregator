class AddDescriptionAndThumbnailToVideos < ActiveRecord::Migration[7.1]
  def change
    add_column :videos, :description, :text
    add_column :videos, :thumbnail, :string
  end
end
