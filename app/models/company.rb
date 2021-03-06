class Company < ActiveRecord::Base
  # Paperclip functionality
  has_attached_file :logo,
                    :styles         => { :thumb => ["150x150>", :png] },
                    :convert_options => { :thumb => "-background transparent -gravity center -extent 150x150" },
                    :storage        => :s3,
                    :path           => "#{ ENV['RAILS_ENV'] }/companies/:id/:style_:filename",
                    :bucket         => Configs.s3_bucket,
                    :s3_credentials => { :access_key_id     => Configs.s3_key,
                                         :secret_access_key => Configs.s3_secret }

  # Validation
  validates_presence_of :name, :submitter_name
  validates_format_of :submitter_email, :with => ARValidation::EMAIL_RE
  validates_format_of :link, :with => ARValidation::URI_RE
  validates_attachment_presence :logo
  validates_attachment_size :logo, :less_than => 1.megabytes
  validates_attachment_content_type :logo, :content_type => [/^image\/.*$/], :message => 'is not an image'
  
  # Set attributes available for mass-assignment
  attr_accessible :name, :submitter_name, :submitter_email, :link, :logo, :is_partner, :is_published
end
