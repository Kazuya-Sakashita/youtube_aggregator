class CreateVideos < ActiveRecord::Migration[7.1]
  def change
    create_table :videos do |t|
      t.string :video_id
      t.string :title
      t.integer :view_count

      t.timestamps
    end
  end
end
