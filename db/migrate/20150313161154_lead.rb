class Lead < ActiveRecord::Migration
  def change
  	create_table :leads do |t|
  		t.string :name,								null: false
  		t.string :email,							null: false
  		t.integer :referral_count,		default: 0
  		t.string :referral_code,			null: false

  		t.timestamps
  	end
  end
end
