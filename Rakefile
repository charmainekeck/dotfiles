#------------------------------------------------------------------------------
#          FILE:  Rakefile
#   DESCRIPTION:  Installs and uninstalls dot configuaration files.
#        AUTHOR:  Adam Walz <viperlight89@me.com>
#       VERSION:  1.0.0
#------------------------------------------------------------------------------

require 'date'
require 'open3'
require 'fileutils'
require 'rubygems'
require 'rake'
require 'erb'

# Raised when a Keychain item is not found.
class KeychainError < Exception
end

# Utility function for displaying messages.
def info(text)
  STDOUT.puts text
end

# Utility function for displaying error messages.
def error(text)
  STDERR.puts "Error: #{text}"
end

class Platform
  def self.mac?
    RUBY_PLATFORM.include? 'darwin'
  end

  def self.linux?
    RUBY_PLATFORM.include? 'linux'
  end

  def self.windows?
  RUBY_PLATFORM.include? 'windows'
  end
end

# This Rakefile is written for Mac OS X system Ruby.
if RUBY_VERSION >= '1.9'
  error "Ruby 1.8.7 is required to run this Rakefile"
  exit 1
end

RAW_FILE_EXTENSION = 'rrc'
RAW_FILE_EXTENSION_REGEXP = /\.#{RAW_FILE_EXTENSION}$/

KEYCHAIN_GENERIC_PASSWORD_COMMAND = 'security find-generic-password -gl'
KEYCHAIN_INTERNET_PASSWORD_COMMAND = 'security find-internet-password -gl'
ACCOUNT_REGEXP = /"acct"<blob>=(?:0x([0-9A-F]+)\s*)?(?:"(.*)")?$/
PASSWORD_REGEXP = /^password: (?:0x([0-9A-F]+)\s*)?(?:"(.*)")?$/

SCRIPT_PATH = File.split(File.expand_path(__FILE__))
SCRIPT_NAME = SCRIPT_PATH.last
CONFIG_DIR_PATH = SCRIPT_PATH.first

SUBLIME_DIR_PATH = "#{CONFIG_DIR_PATH}/sublime"

BACKUP_DIR_PATH = File.join(
  ENV['HOME'],
  '.dotfiles_backup',
  DateTime.now.strftime('%Y-%m-%d-%H-%M-%S'))

EXCLUDES = [
  SCRIPT_NAME,
  '.DS_Store',
  '.git',
  '.gitignore',
  '.gitmodules',
  'brew',
  'sublime',
  'README.md',
  /.*~$/,
  /^\#.*\#$/,
  /backup\/.*$/,
]

# Wrapper around OS X Keychain.
module Keychain
  # Holds previously requested Keychain items.
  @@cache = {}

  # Wrapper around a Keychain item.
  class Item
    # Returns the accout name.
    attr_reader :account
    # Returns the account password.
    attr_reader :password

    # Returns a new Keychain item.
    #
    # @param [String] account the account name.
    # @param [String] password the account password.
    # @return [Item] the Keychain item.
    def initialize(account, password)
      @account = account or raise ArgumentError, "Account cannot be nil"
      @password = password or raise ArgumentError, "Password cannot be nil"
    end
  end

  # Returns a Keychain item.
  #
  # @param [String] label the Keychain item label.
  # @return [Item] the Keychain item.
  def self.[](label)
    return @@cache[label] if @@cache.has_key? label
    retry_times = 2
    keychain_command = KEYCHAIN_INTERNET_PASSWORD_COMMAND
    begin
      stdin, stdout, stderr = Open3.popen3("#{keychain_command} '#{label}'")
      output = stdout.readlines.join + stderr.readlines.join
      [stdin, stdout, stderr].each { |stdio| stdio.close }
      if output =~ /The specified item could not be found in Keychain\./
        raise NameError
      end
      # The field value is stored in hexademical (one) or string (two).
      field_value = lambda do |one, two|
        return one.scan(/../).map { |tuple| tuple.hex.chr }.join unless one.nil?
        return two unless two.nil?
        return ""
      end
      account = output[ACCOUNT_REGEXP].gsub!(ACCOUNT_REGEXP) { field_value[$1, $2] }
      password = output[PASSWORD_REGEXP].gsub!(PASSWORD_REGEXP) { field_value[$1, $2] }
      @@cache[label] = Item.new(account, password)
    rescue NameError
      keychain_command = KEYCHAIN_GENERIC_PASSWORD_COMMAND
      retry_times -= 1
      if retry_times > 0
        retry
      else
        raise KeychainError, "Item '#{label}' could not be found in Keychain"
      end
    rescue IOError
      raise KeychainError, "Could not communicate with Keychain for item '#{label}'"
    end
  end
end

# Moves an existing dot file into the backup directory.
#
# @param [String] from the file to back up.
# @param [String] to the backup destination.
def backup(from, to)
  return unless File.exists? from
  FileUtils.mkdir_p(File.dirname(to))
  File.rename(from, to)
end

# Returns whether a path is excluded from linking into the home directory.
#
# @param [String] path the path a to file or directory.
# @return [true, false] if true, the path is excluded; otherwise, it is not.
def excluded?(path)
  strings = EXCLUDES.select { |item| item.class == String }
  regexps = EXCLUDES.select { |item| item.class == Regexp }
  excluded = strings.include? path
  regexps.each do |pattern|
    excluded = true if path =~ pattern
  end
  return excluded
end

# Returns whether a command exists in PATH.
#
# @param [String] command the name of the command.
# @return [true, false] if true, the command exists; otherwise, it does not.
def exists?(command)
  ENV['PATH'].split(':').any? do |directory|
    File.exists?(File.join(directory, command))
  end
end

namespace :dotfiles do
  desc('Links dofiles')
  task :link => [:link_dotfiles, :link_sublime]

  task :link_dotfiles do
    Dir["#{CONFIG_DIR_PATH}/*"].each do |source|
      target_relative = source.gsub("#{CONFIG_DIR_PATH}/", '')
      target_backup = File.join(BACKUP_DIR_PATH, target_relative)
      target = File.join(ENV['HOME'], ".#{target_relative}")
      # Do not link if the source is a raw file, the target already exists and
      # is a symlink to the source.
      next if source =~ RAW_FILE_EXTENSION_REGEXP \
      or excluded?(target_relative) \
      or (File.exists?(target) \
        and File.ftype(target) == 'link' \
        and File.identical?(source, target))
      link_and_backup(source, target, target_relative)
    end
  end

  task :link_sublime do
    Dir["#{SUBLIME_DIR_PATH}/*"].each do |source|
      target_relative = source.gsub("#{SUBLIME_DIR_PATH}/", '')
      tartget_backup = File.join(BACKUP_DIR_PATH, target_relative)
      preference_type = target_relative =~ /.*\(.+\).+/ ? 'Default' : 'User'
      target = File.join(sublime_package_path, preference_type, target_relative)

      next if (File.exists?(target) \
        and File.ftype(target) == 'link' \
        and File.identical?(source, target))
      link_and_backup(source, target, target_relative)
    end
  end

  desc 'Render raw dot files'
  task :render do
    Dir["#{CONFIG_DIR_PATH}/**/*.#{RAW_FILE_EXTENSION}"].each do |source|
      target = source.gsub(RAW_FILE_EXTENSION_REGEXP, '')
      next if excluded? source
      if File.file? source
        begin
          source_contents = File.read source
          source_contents = ERB.new(source_contents).result(binding)
        rescue IOError
          error "Could not read raw file '#{source}'"
        rescue NameError, SyntaxError => e
          error "Could not render raw file '#{source}'.\n\n#{e.message}"
        rescue KeychainError => e
          error e.message
        end
        begin
          target_contents = File.exists?(target) ? File.read(target) : nil
          # Only overwrite the rendered dot file if the raw file has changed.
          if source_contents != target_contents
            File.open(target, 'w') do |file|
              info "Writing: #{target}"
              file.write source_contents
              file.chmod 0600
            end
          end
        rescue IOError
          error "Could not write file '#{target}'"
        end
      end
    end
  end

  desc 'Uninstall dot files'
  task :uninstall => 'dotfiles:clean' do
    # unlink dotfiles from home directory
    Dir["#{CONFIG_DIR_PATH}/*"].each do |source|
      target_relative = source.gsub("#{CONFIG_DIR_PATH}/", '')
      target = File.join(ENV['HOME'], ".#{target_relative}")
      next if source =~ RAW_FILE_EXTENSION_REGEXP or excluded?(target_relative)
      unlink(source, target)
    end
    # unlink sublime preferences
    Dir["#{sublime_package_path}/*"].each do |source|
      target = source.gsub("#{SUBLIME_DIR_PATH}/", '')
      next if source =~ RAW_FILE_EXTENSION_REGEXP or excluded?(target)
      unlink(source, target)
    end
  end

  desc 'Unlink broken symlinks'
  task :clean do
    Dir["#{ENV['HOME']}/.*"].each do |item|
      unlink_if_broken(item)
    end
    Dir["#{sublime_package_path}/*"].each do |item|
      unlink_if_broken(item)
    end
  end

  def link_and_backup(source, target, backup)
    info "Linking: #{target}"
    begin
      backup(target, backup)
    rescue IOError
      error "Could not backup '#{target}', will skip symlinking '#{source}'"
      next
    end
    begin
      FileUtils.mkdir_p(File.dirname(target))
      File.symlink(source, target)
    rescue IOError
      error "Could not symlink '#{source}' to '#{target}'"
    end
  end

  def unlink_if_broken(file)
    if File.ftype(file) == 'link'
      unless File.exists? file
        info "Unlinking: #{file}"
        begin
          File.unlink file
        rescue IOError
          error "Could not unlink '#{file}'"
        end
      end
    end
  end

  def unlink(source, target)
    # Uninstall only if the target exists, is a symlink, and points to source.
    if File.exists?(target) \
      and File.ftype(target) == 'link' \
      and File.identical?(source, target)
      info "Unlinking: #{target}"
      begin
        File.unlink target
      rescue IOError
        error "Could not unlink '#{target}'"
      end
    end
  end

  def sublime_package_path
    if Platform.mac?
      "#{ENV['HOME']}/Library/Application Support/Sublime Text 3/Packages"
    elsif Platform.linux?
      "#{ENV['HOME']}/.Sublime Text 3/Packages"
    else
      "#{ENV['APPDATA']}\\Sublime Text 3/Packages"
    end
  end
end

namespace :module do
  desc 'Initialize git submodules'
  task :init do
    if File.exists? '.gitmodules'
      unless exists?('git')
        error "Could not initialize submodules, Git is not found"
        next
      end
      # Popen3 does not return the exit status code.
      # Echo it onto the last line of stderr.
      Open3.popen3(
        "git submodule update --init --recursive; echo $? 1>&2"
        ) do |stdin, stdout, stderr|
        stdios = [stdin, stdout, stderr]
        threads = []
        threads << Thread.new do
          Thread.current.abort_on_exception = true
          stdout.each do |line|
            next if line !~ /^Cloning into .*\.{3}$/
            info line.gsub(/^Cloning into (.*)\.{3}$/, "Initializing: \\1")
          end
        end
        threads << Thread.new do
          Thread.current.abort_on_exception = true
          stderr.each do |line|
            if line =~ /Unable to checkout '[^']+' in submodule path '([^']+)'/
              error "Could not initialize submodule '#{$1}'"
            end
            if stderr.eof? and line.to_i != 0
              error "Could not initialize submodules"
            end
          end
        end
        begin
          threads.each(&:join)
          stdios.each(&:close)
        rescue Exception => e
          error e.message if e.class == IOError
        end
      end
    end
  end

  desc 'Make submodules'
  task :make do
    Dir["#{CONFIG_DIR_PATH}/**/Rakefile"].each do |rake_file|
      next if SCRIPT_PATH.join('/') == rake_file
      submodule = File.dirname rake_file
      submodule_relative = submodule.gsub("#{CONFIG_DIR_PATH}/", '')
      read, write = IO.pipe
      pid = fork do
        Dir.chdir submodule
        Rake::Task.clear
        load rake_file
        next unless Rake::Task.task_defined?(:make)
        info "Making: #{submodule_relative}"
        # Redirect stdout, stderr since make is noisy.
        stdout_old = STDOUT.clone
        stderr_old = STDERR.clone
        begin
          STDOUT.reopen write
          STDERR.reopen STDOUT
          read.close
          Rake::Task[:make].invoke
        rescue Exception => e
          STDOUT.reopen stdout_old
          STDERR.reopen stderr_old
          error e.message
        end
      end
      begin
        write.close
        read.each do |line|
          if read.eof? and line =~ /error:/i
            error "Could not make '#{submodule_relative}'"
          end
        end
      rescue IOError => e
        error e.message
      end
      Process.waitpid pid
    end
  end

  desc 'Update submodules'
  task :update do
    if File.exists? '.gitmodules'
      unless exists?('git')
        error "Could not update submodules, Git is not found"
        next
      end
      # Popen3 does not return the exit status code.
      # Echo it onto the last line of stderr.
      Open3.popen3(
        "git submodule foreach git pull origin master; echo $? 1>&2"
        ) do |stdin, stdout, stderr|
        stdios = [stdin, stdout, stderr]
        threads = []
        threads << Thread.new do
          stdout.each do |line|
            if line =~ /Entering '([^']+)'/
              info "Updating: #{$1}"
            end
          end
        end
        threads << Thread.new do
          stderr.each do |line|
            if line =~ /Stopping at '([^']+)'/
              error "Could not update submodule '#{$1}'"
            end
            if stderr.eof? and line.to_i != 0
              error "Could not update submodules"
            end
          end
        end
        begin
          threads.each(&:join)
          stdios.each(&:close)
          Rake::Task[:make].invoke
        rescue Exception => e
          error e.message if e.class == IOError
        end
      end
    end
  end
end

namespace :homebrew do
  desc "Installs homebrew"
  task :install => [:brew_install, :formula_install]

  desc "Updates package list and upgrades to latest version"
  task :update => [:brew_update, :formula_install, :brew_upgrade]

  task :brew_install do
    if Platform.mac? and not exists? "brew"
      info "Installing homebrew"
      sh "ruby -e \"$(curl -fsSL https://raw.github.com/mxcl/homebrew/go)\""
      sh "brew doctor"
    end
  end

  task :brew_update => :brew_install do
    next if not Platform.mac?
    sh "brew update"
    sh "brew doctor"
  end

  task :brew_upgrade => :brew_update do
    next if not Platform.mac?
    sh "brew upgrade"
    sh "brew cleanup"
  end

  task :formula_install => :brew_update do
  	next if not Platform.mac?
    formula_list = []
    FileList["brew/*"].each do |f|
      file = File.new(f, "r")
      while (line = file.gets)
        # Don't installed commented or invalid lines
        formula_list << line.chomp if not line =~ /^(#.*|\s*$)/
      end
    end
    # Remove packages that are already installed
    installables = formula_list - %x[brew list].split(/\s/)
    installables.each do |formula|
      sh "brew install #{formula}" do |ok, res|
        # install, but don't die if brew throws an error
      end
    end
  end
end

desc 'Install dot files'
task :install => [
  'homebrew:install',
  'homebrew:update',
  'module:init',
  'dotfiles:render',
  'dotfiles:link',
  'dotfiles:clean',
  'module:make'
  ] do
    info "Backup: #{BACKUP_DIR_PATH}" if File.directory? BACKUP_DIR_PATH
  end

  task :default => [:install]