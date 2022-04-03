module setup
using ZipFile
using Tar, CodecZlib
using ..gmsh


function include_setup(file_path)
    setup_file::String = """ include("setup.jl") """
    temp_file = joinpath(dirname(file_path), "temp.jl")
    last_end_closure_ln = [1,]
    ins_flag = true
    open(file_path, "r") do io
        counter = 1
        for i in eachline(io)
            if strip(i) == setup_file
                ins_flag = false
            elseif startswith(strip(i), "end")
                last_end_closure_ln[1] = counter
            end
            counter += 1
        end
    end

    last_end_closure_lnn = last_end_closure_ln[1]

    if ins_flag
        open(file_path) do input
            open(temp_file, "w") do output
                for (k, line) in enumerate(eachline(input))
                    if k == last_end_closure_lnn
                        println(output, setup_file * "\n" * line)
                    else
                        println(output, line)
                    end
                end
            end
        end
    end
    cp(temp_file, file_path; force = true)
    rm(temp_file)
end


function setup_on_apple() end


function setup_on_linux(;
    req_version = "4.8.4",
    scratch_dir::String = mkpath(joinpath(homedir(), "gmsh_scratch_dir"))
)
    # ===========================================
    #   download the file to scratch directory
    # ===========================================
    file_head = "gmsh-$(req_version)-Linux$(Sys.WORD_SIZE)-sdk"
    file_name = file_head * ".tgz"
    url_path = "http://gmsh.info/bin/Linux/" * file_name
    gmsh_scratch_file = joinpath(scratch_dir, file_name)
    if !isfile(gmsh_scratch_file)
        println("Downloading ", url_path, " to ", scratch_dir)
        download(url_path, gmsh_scratch_file)
		println("Finished downloading..!")
    else
        printstyled("Note: "; color = :yellow)
        println("skipping the download as the required file already exists at the destination!
        If you want to overwrite the existing file, pass overwrite=true keyword")
    end

    # ===========================================
    #       Extracting the necessary files
    # ===========================================

    major_version, minor_version, patch = split(req_version, ".")

    required_files = (
        "gmsh.jl",
        "libgmsh.so",
        "libgmsh.so.$major_version.$minor_version",
        "libgmsh.so.$major_version.$minor_version.$patch",
    )

    extraction_dir = joinpath(scratch_dir, "extr_dir")
    open(GzipDecompressorStream, gmsh_scratch_file) do io
        Tar.extract(io, extraction_dir)
    end
    #"C:\Users\rajeshnakka\gmsh_scratch_dir\test\gmsh-4.8.4-Linux64-sdk\lib\gmsh.jl"
    req_file_suffix = joinpath(extraction_dir, file_head, "lib")
    # for a_file_name in required_files
      # writing_file_path = joinpath(req_file_suffix, a_file_name)
      # println("Using the file ", writing_file_path)
    # end

    # ===========================================
    #       Copying the setup module to gmsh.jl
    # ===========================================

    include_setup(joinpath(req_file_suffix, "gmsh.jl"))

    # copying to the destination
    for a_file in required_files
        print("Copying ", a_file, " ===>> ", dirname(pathof(gmsh)))
        cp(joinpath(req_file_suffix, a_file), joinpath(dirname(pathof(gmsh)), a_file); force = true)
		println("\t\tDone!")
    end
	
	# extraction_dir
	if isdir(scratch_dir)
		print("Cleaning the scratch directory...")
		rm(extraction_dir; force=true, recursive=true)
		println("\t\tDone!")
	end
	
	if isdir(extraction_dir)
		print("Cleaning the extraction directory...")
		rm(extraction_dir; force=true, recursive=true)
		println("\t\tDone!")
	end
	
end

function setup_on_windows(;
    req_version = "4.8.4",
    scratch_dir::String = mkpath(joinpath(homedir(), "gmsh_scratch_dir"))
)
    # ===========================================
    #   download the file to scratch directory
    # ===========================================
    file_head = "gmsh-$req_version-Windows$(Sys.WORD_SIZE)-sdk"
    file_name = file_head * ".zip"
    url_path = "http://gmsh.info/bin/Windows/" * file_name
    gmsh_scratch_file = joinpath(scratch_dir, file_name)
    if !isfile(gmsh_scratch_file)
        println("Downloading ", url_path, " to ", scratch_dir)
        download(url_path, gmsh_scratch_file)
    else
        printstyled("Note: "; color = :yellow)
        println("skipping the download as the required file already exists at the destination!
        If you want to overwrite the existing file, pass overwrite=true keyword")
    end

    # ===========================================
    #       Extracting the necessary files
    # ===========================================

    major_version, minor_version, patch = split(req_version, ".")

    required_files = ("gmsh.jl", "gmsh-$major_version.$minor_version.dll")
    bin_directory = ZipFile.Reader(gmsh_scratch_file)
    for a_file in bin_directory.files
        a_file_path = a_file.name
        a_file_name = ('/' in a_file_path ? split(a_file_path, '/') : split(a_file_path, '\\'))[end]
        if a_file_name in required_files
            print("Extracting ", a_file_name)
            writing_file_path = joinpath(scratch_dir, a_file_name)
            write(writing_file_path, read(a_file))
            println("\t\tDone!")
        end
    end
    close(bin_directory)

    # ===========================================
    #       Copying the setup module to gmsh.jl
    # ===========================================

    include_setup(joinpath(scratch_dir, "gmsh.jl"))

    # copying to the destination
    for a_file in required_files
        print("Copying ", a_file, " to ", dirname(pathof(gmsh)))
        cp(joinpath(scratch_dir, a_file), joinpath(dirname(pathof(gmsh)), a_file); force = true)
        println("\t\tDone!")
    end
end

function run(;
    req_version = "4.8.4",
    scratch_dir::String = mkpath(joinpath(homedir(), "gmsh_scratch_dir"))
)

    if Sys.iswindows()
        setup_on_windows(; req_version, scratch_dir)
    elseif Sys.islinux()
        setup_on_linux(; req_version, scratch_dir)
    elseif Sys.isapple()
        setup_on_apple(; req_version, scratch_dir)
    end
end

end
