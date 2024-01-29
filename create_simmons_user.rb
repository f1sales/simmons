# frozen_string_literal: true

def gen_password
  password = 3.times.map { rand(1..9) }.join('')
  password += %i[@ % - = & #].sample.to_s
  password += 3.times.map { rand(1..9) }.join('')

  password
end

def emailize(string)
  string.dup.force_encoding('UTF-8').unicode_normalize(:nfkd).encode('ASCII', replace: '').downcase.gsub(/\W+/, '')
end

SIMMONS_EMAIL_DOMAIN = '@simmons.com.br'

Admin.skip_callback(:create, :after, :subscribe_mail_list)
Salesman.skip_callback(:create, :after, :send_sign_up_instructions)

adm_names = [
  'Simmons Concept Uberaba',
  'Grupo Yasin'
]

stores = [
  'Santa Maria - Avenida Santa Beatriz da Silva, 1130 - Simmons Concept Uberaba',
  'Itam Bibi - Avenida Presidente Juscelino Kubitschek, 900 - Grupo Yasin'
]

resp_s = []
resp_a = []

stores.each_with_index do |store, i|
  # 1. admmin
  # 2. gen teams
  # 3. gen salesman
  salesman_name, team_name = store.split(' - ')[1..].map(&:strip)
  salesman_email = emailize(salesman_name)
  salesman_email += SIMMONS_EMAIL_DOMAIN
  admin_name = adm_names[i]
  admin_email = "#{emailize(team_name)}#{SIMMONS_EMAIL_DOMAIN}"
  team = Team.find_or_create_by!(name: team_name)
  adm = Admin.where(email: admin_email).first
  puts team
  puts '-------'
  puts "Team: #{team.name} - ID: #{team.id}"
  puts '-------'

  if adm.nil?
    admin_attr = { email: admin_email, password: (gen_password + gen_password), name: admin_name,
                   confirmed_at: Time.now, team: team }
    Admin.create!(admin_attr)
    puts "\n\nAdmin"
    puts admin_attr
    resp_a << admin_attr
    puts '-------'
    n = resp_a.size - 1
    puts "Email: #{resp_a[n][:email]} -> Password: #{resp_a[n][:password]}"
    puts "Pattern: #{resp_a[n][:email]},#{resp_a[n][:password]}"
    puts '-------'
  else
    puts "\n\nAdmin: #{adm.email} already exists."
    puts "Name: #{adm.name}, ID: #{adm.id}"
  end

  salesman_attr = { name: salesman_name, email: salesman_email, teams: [team], phone: rand(99_999_999_999),
                    password: gen_password }
  Salesman.create!(salesman_attr)
  puts "\n\nSalesman"
  puts salesman_attr
  resp_s << salesman_attr
  puts '-------'
  puts "Email: #{resp_s[i][:email]} -> Password: #{resp_s[i][:password]}"
  puts "Pattern: #{resp_s[i][:email]},#{resp_s[i][:password]}"
  puts '-------'
  puts "\n"
  puts '=======' * 10
  puts '=======' * 10
  puts "\n\n\n"
end;''


# Admin that already exists, but is not in the spreadsheet
# password  = (gen_password + gen_password)
# Admin.where(email: email).first.update(password: password)
