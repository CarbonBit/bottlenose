require 'rubygems/package'
require 'zlib'

TAR_LONGLINK = '././@LongLink'


class SubTarball
  def initialize(as_id)
    @as = Assignment.find(as_id)
  end

  def update!
    temp = Rails.root.join('tmp', 'tars', 'assign', @as.id.to_s)
    if temp.to_s =~ /tars\/assign/
      FileUtils.rm_rf(temp)
    end

    FileUtils.mkdir_p(temp)

    afname = "assignment_#{@as.id}"

    dirs = temp.join(afname)
    FileUtils.mkdir_p(dirs)

    @as.all_used_subs.each do |sub|
      next if sub.file_full_path.blank?

      uu = sub.user
      dd = dirs.join(uu.dir_name)
      FileUtils.mkdir_p(dd)

      FileUtils.cp(sub.file_full_path, dd)
    end

    FileUtils.cd(temp)
    system(%Q{tar czf "#{afname}.tgz" "#{afname}"})

    src = temp.join("#{afname}.tgz")

    FileUtils.cp(src, @as.tarball_full_path)
  end

  def update_moss!
    temp = Rails.root.join('tmp', 'tars', 'assign', @as.id.to_s)
    if temp.to_s =~ /tars\/assign/
      FileUtils.rm_rf(temp)
    end

    FileUtils.mkdir_p(temp)

    afname = "assignment_#{@as.id}"

    dirs = temp.join(afname)
    FileUtils.mkdir_p(dirs)


    @as.all_used_subs.each do |sub|
      next if sub.upload.nil?

      uu = sub.user
      @dd = dirs.join(uu.dir_name)
      FileUtils.mkdir_p(@dd)

      def copy_files(extracted)
        if extracted[:children]
          extracted[:children].each {|c| copy_files c}
        else
          FileUtils.cp(extracted[:full_path],
                       @dd.join(extracted[:full_path].to_s.gsub(/.*extracted\//, "").gsub("/", "_").gsub(" ", "_")))
        end
      end
      sub.upload.extracted_files.each {|e| copy_files e}
    end

    
    FileUtils.cd(temp)
    system(%Q{tar czf "#{afname}.tgz" "#{afname}"})
    
    src = temp.join("#{afname}.tgz")

    FileUtils.cp(src, @as.tarball_full_path)    
  end

  def path
    @as.tarball_path
  end

  def self.untar(source, dest)
    self.untar_source(File.open(source), dest)
  end

  def self.untar_gz(source, dest)
    self.untar_source(Zlib::GzipReader.open(source), dest)
  end

  def self.count_files(source)
    return self.count_files(File.open(source)) if source.is_a? String
    count = 0
    Gem::Package::TarReader.new(source) do |tar|
      tar.each do |entry|
        next if entry.full_name == TAR_LONGLINK
        next if entry.directory?
        count += 1
      end
    end
    return count
  end

  def self.count_files_gz(source)
    return self.count_files(Zlib::GzipReader.open(source))
  end
  
private
  def self.untar_source(source, destination)
    # from https://dracoater.blogspot.com/2013/10/extracting-files-from-targz-with-ruby.html
    Gem::Package::TarReader.new(source) do |tar|
      dest = nil
      tar.each do |entry|
        if entry.full_name == TAR_LONGLINK
          dest = File.join destination, entry.read.strip
          next
        end
        dest ||= File.join destination, entry.full_name
        if entry.directory?
          FileUtils.rm_rf dest unless File.directory? dest
          FileUtils.mkdir_p dest, :mode => entry.header.mode, :verbose => false
        elsif entry.file?
          FileUtils.rm_rf dest unless File.file? dest
          FileUtils.mkdir_p(File.dirname(dest))
          File.open dest, "wb" do |f|
            f.print entry.read
          end
          FileUtils.chmod entry.header.mode, dest, :verbose => false
        elsif entry.header.typeflag == '2' #Symlink!
          File.symlink entry.header.linkname, dest
        end
        dest = nil
      end
    end
  end
end
