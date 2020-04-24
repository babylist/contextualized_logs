class CreateModel < ActiveRecord::Migration[5.2]
  def change
    create_table :models do |t|
      t.string 'value'
    end
  end
end
