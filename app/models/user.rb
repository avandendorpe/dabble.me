class User < ActiveRecord::Base
  # Include default devise modules. Others available are:
  # :confirmable, :lockable, :timeoutable and :omniauthable
  devise :database_authenticatable, :registerable,
         :recoverable, :rememberable, :trackable, :validatable

  randomized_field :user_key, length: 18, prefix: 'u'

  has_many :entries, dependent: :destroy
  has_many :payments

  serialize :frequency, Array

  scope :subscribed_to_emails, -> { where("frequency NOT LIKE '%[]%'") }
  scope :not_just_signed_up, -> { where("created_at < (?)", DateTime.now - 18.hours) }
  scope :daily_emails, -> { where(frequency: "---\n- Sun\n- Mon\n- Tue\n- Wed\n- Thu\n- Fri\n- Sat\n") }
  scope :with_entries, -> { includes(:entries).where("entries.id > 0").references(:entries) }
  scope :without_entries, -> { includes(:entries).where("entries.id IS null").references(:entries) }
  scope :free_only, -> { where("plan ILIKE '%free%' OR plan IS null") }
  scope :pro_only, -> { where("plan ILIKE '%pro%'") }
  scope :monthly, -> { where("plan ILIKE '%monthly%'") }
  scope :yearly, -> { where("plan ILIKE '%yearly%'") }
  scope :forever, -> { where("plan ILIKE '%forever%'") }
  scope :paypal_only, -> { where("plan ILIKE '%paypal%'") }
  scope :gumroad_only, -> { where("plan ILIKE '%gumroad%'") }
  scope :not_forever, -> { where("plan NOT ILIKE '%forever%'") }
  scope :referrals, -> { where("referrer IS NOT null") }

  before_save { email.downcase! }
  after_commit :restrict_free_frequency, on: [:create, :update]
  after_create do
    send_welcome_email
    subscribe_to_mailchimp if Rails.env.production?
  end

  def full_name
    "#{first_name} #{last_name}" if first_name.present? || last_name.present?
  end

  def abbreviated_name
    "#{first_name} #{last_name.first&.upcase}"
  end  

  def cleaned_to_address
    "#{full_name.gsub(/[^\w\s-]/i, '') if full_name.present?} <#{email}>"
  end  

  def full_name_or_email
    first_name.present? ? "#{first_name} #{last_name}" : email
  end

  def first_name_or_fallback(fallback='there')
    first_name.present? ? "#{first_name}" : fallback
  end

  def frequencies
    frequency.to_sentence
  end

  def random_entry(entry_date=nil)
    if entry_date.present?
      entry_date = Date.parse(entry_date.to_s)
      if Date.leap?(entry_date.year) && entry_date.month == 2 && entry_date.day == 29 && leap_year_entry = random_entries.where(date: entry_date - 4.years).first
        leap_year_entry
      elsif exactly_last_year_entry = random_entries.where(date: entry_date.last_year).first
        exactly_last_year_entry
      elsif (emails_sent % 3 == 0) && (exactly_30_days_ago = random_entries.where(date: entry_date.last_month).first)
        exactly_30_days_ago
      elsif (emails_sent % 5 == 0) && (exactly_7_days_ago = random_entries.where(date: entry_date - 7.days).first)
        exactly_7_days_ago
      elsif (emails_sent % 2 == 0) && (count = random_entries.where('date < (?)', entry_date.last_year).count) > 30
        random_entries.where('date < (?)', entry_date.last_year).offset(rand(count)).first #grab entry way back
      else
        self.random_entry
      end
    else
      if (count = random_entries.count) > 0
        random_entries.offset(rand(count)).first
      end
    end
  end

  def existing_entry(selected_date)
    selected_date = Date.parse(selected_date.to_s)
    entries.where(date: selected_date).first
    rescue
      nil
  end

  def is_admin?
    admin_emails.include?(self.email)
  end

  def is_pro?
    plan_name == 'Dabble Me PRO'
  end

  def is_free?
    !is_pro?
  end

  def plan_name
    if plan && plan.match(/pro/i)
      'Dabble Me PRO'
    else
      'Dabble Me Free'
    end
  end

  def plan_frequency
    if plan && plan.match(/monthly/i)
      'Monthly'
    elsif plan && plan.match(/yearly/i)
      'Yearly'
    end
  end

  def plan_type
    if plan && plan.match(/gumroad/i)
      'Gumroad'
    elsif plan && plan.match(/paypal/i)
      'PayPal'
    end
  end

  def plan_details
    p = plan_name
    p = p + ' ' + plan_frequency if plan_frequency.present?
    p = p + ' on ' + plan_type if plan_type.present?
    p
  end

  def days_since_last_post
    if last_post = self.entries.where("date < ?", Time.now).first
      ActionController::Base.helpers.number_with_delimiter((Time.now.to_date - last_post.date.to_date).to_i)
    else
      ''
    end
  end

  def past_filter_entry_ids
    if (filters = self.past_filter).present?
      filter_names = filters.split(',').map(&:strip)
      cond_text = filter_names.map{|w| "LOWER(entries.body) like ?"}.join(" OR ")
      cond_values = filter_names.map{|w| "%#{w}%"}
      self.entries.where(cond_text, *cond_values).pluck(:id)
    end
  end

  def random_entries
    entries.where.not(id: past_filter_entry_ids)
  end

  private

  def restrict_free_frequency
    if self.is_free? && self.frequency.present? && ENV['FREE_WEEK'] != 'true'
      self.update_column(:frequency, [self.frequency.first])
    end
  end

  def subscribe_to_mailchimp
    if ENV['MAILCHIMP_API_KEY'].present?
      gb = Gibbon::API.new
      begin
        gb.lists.subscribe({
          id: ENV['MAILCHIMP_LIST_ID'],
          email: {:email => self.email},
          merge_vars: {
            :FNAME => self.first_name,
            :LNAME => self.last_name,
            :GROUP => "Signed Up" },
          double_optin: false,
          update_existing: true})
      rescue
        # already subscribed or issues with Mailchimp's API
      end
    end
  end

  def send_welcome_email
    UserMailer.welcome_email(self).deliver_later
  rescue StandardError => e
    Rails.logger.warn("Error sending email to #{self.email}: #{e}")
  end

  def admin_emails
    ENV.fetch('ADMIN_EMAILS').split(',')
  end
end
