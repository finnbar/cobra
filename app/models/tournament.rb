class Tournament < ApplicationRecord
  has_many :players, -> { order(:id) }, dependent: :destroy
  belongs_to :user
  has_many :stages, -> { order(:number) }, dependent: :destroy
  has_many :rounds, through: :stages

  enum stage: {
    swiss: 0,
    double_elim: 1
  }

  delegate :pair_new_round!, to: :current_stage

  validates :name, :slug, presence: true
  validates :slug, uniqueness: true

  before_validation :generate_slug, on: :create, unless: :slug
  before_create :default_date, unless: :date
  after_create :create_stage

  def cut_to!(format, number)
    previous_stage = current_stage
    stages.create!(
      format: format,
      number: previous_stage.number + 1
    ).tap do |stage|
      previous_stage.top(number).each_with_index do |player, i|
        stage.registrations.create!(
          player: player,
          seed: i + 1
        )
      end
    end
  end

  def close_registration!
    players.active.update(registration_locked: true)
    update(all_players_unlocked: false, any_player_unlocked: false)
  end

  def unlock_decks!
    players.active.update(registration_locked: false)
    update(all_players_unlocked: true, any_player_unlocked: true)
  end

  def corp_counts
    players.group_by(&:corp_identity).map do |id, players|
      [
        Identity.find_or_initialize_by(name: id),
        players.count
      ]
    end.sort_by(&:last).reverse
  end

  def runner_counts
    players.group_by(&:runner_identity).map do |id, players|
      [
        Identity.find_or_initialize_by(name: id),
        players.count
      ]
    end.sort_by(&:last).reverse
  end

  def generate_slug
    self.slug = rand(Integer(36 ** 4)).to_s(36).upcase
    generate_slug if Tournament.exists?(slug: slug)
  end

  def current_stage
    stages.last
  end

  def unlocked_deck_players
    players.active.where('registration_locked IS NOT TRUE')
  end

  def locked_deck_players
    players.active.where('registration_locked IS TRUE')
  end

  def decks_status_description
    if all_players_unlocked?
      'all unlocked'
    elsif any_player_unlocked?
      'partially unlocked'
    else
      'all locked'
    end
  end

  private

  def default_date
    self.date = Date.current
  end

  def create_stage
    stages.create(
      number: 1,
      format: :swiss
    )
  end
end
