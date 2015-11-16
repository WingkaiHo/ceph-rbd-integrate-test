#CEPH cluster integrate test

	We have 4 server for ceph cluster. Each server have 6 osd disk and 2 ssd for journal. We use this project to do stress test:
		- First get the cloud disk throughput and iops which run on ceph cluster RBD.
		- Second, multi vm concurrent run fio instance. How many instanc vm concurrent run can meet our SLA.
		- Third, our rbd SLA is read/write throughput 40MB/s, 4K rand read/write is IOPS is 100, IO wait less than 20ms

##1.  Environment preparation
###1.1 SSH auto login. Each script run must have ssh auto login support. You can use ssh-auto-login.sh to set auto login. For example:
		ssh-auto-login.sh -l hostlist -p password
        hostlist: The path of ip list file. You can write the ip address in host list which you want to set auto login.
        password：The password the of all host.

##2. Ceph cluster integrate test。

###2.1 SATA throughput and iops test
		throughput BS: 128K 256K 512K 1M, iodepth: 1 2 4 8 16
		IOPS test：BS: 4K 8K 16K 32K  64K 128K, iodepth: 1 2 4 8 16 32

####2.1.1 Appoint SATA disk host IP
		Write the SATA disk host IP addr in file sata

####2.1.2 Execute the shell sata-perf.sh to test SATA disk performance, for example:
		./stat-perf.sh -d /dev/sdx -s size -t 60
        -d: Appoint the disk address for test。
		-s: Appoint the disk space，it need the same as the disk space,if you want to get accuracy perforamce.
		-t: Running time of test case
		The script will help you to run all throughput and IOPS test case，and resend the result to local host directory ~/ceph-perf-test/ it will output the result directory when it shell finished。

####2.1.3 Dump the test result
		./dump-disk-perf.sh -d result_output_dir
        -d result_output_dir : sata performance result which output by script "stat-perf.sh"

##3. Ceph cluster ssd performance。

		The SSD performance must test for more than 30 minute for every test case, this script can assign test case in different host

###3.1 Write the ssd host list in file "ssd"
		Write the SSD host ip to file "ssd", you can write multi ip in this file

###3.1 Execute script ssd-perf.sh for SSD test, for example:
		./ssd-perf.sh -s size -d /dev/sdx -t 3600
        -d: Appoint the SSD disk address for test。
		-s: Appoint the disk space，it need the same as the disk space,if you want to get accuracy perforamce.
		-t: Running time of test case.
		The script will help you to run all throughput and IOPS test case for SSD，and resend the result to local host directory ~/ceph-perf-test/ it will output the result directory when it shell finished。

####3.2 Dump the test result
		./dump-disk-perf.sh -d result_output_dir
        -d result_output_dir : ssd performance result which output by script "ssd-perf.sh"

##4. Single VM performance test for throughput and IOPS。
		BS: 128K 256K 512K 1M， iodepth: 1 2 4 8 16 32 64 
        BS: 4K 8K 16K 32K 64K 128K, iodepth: 1 2 4 8 16 32 64

###4.1 Setting single VM test VM ip address.
		Write the ip address in file "single-vm".

####4.1.1 Appoint VM  IP
		Write the single VM address to file "single-vm"

###4.2 Execute the script singlevm-perf.sh, for example:
		./singlevm-perf.sh -d /dev/sda2 -s size t 60
		-d: Appoint the vm disk for test, such as /dev/sda2
		-s: Appoint the disk space，it need the same as the disk space or partition,if you want to get accuracy perforamce.
		-t: Running time of test case.

###4.3 结果收集和打印
		./dump-disk-perf.sh -d ~/ceph-perf/vmip
        -d vmip 指定在single-vm填写ip地址。

##5. Multi VM stress test

	 Try to creat 100 VM instance. Run fio instance in thease VM.

###5.1 Edit ip address in different test case.
		Edit the ip address for different test case for example 2vm-list, 4vm-list, 8vm-list ... and so on.


###5.2 Run multi VM test script.
		./multivm-perf.sh -d /dev/sda2 -s size t 60 -l xvm-list
		-l xvm-list: Appoint ip list, x representative 2，4, 8, 10, 20, 30, 40, 50, 70, 100. 
		-d appoint the device 
		-s the size of device space.
		
		The default IO depth of multi VM test is 8, you can fix in file "multivm-perf.sh". The result output in directory ~/ceph-test-perf/

###5.3 Collect result of multi VM
		The script use to get average performance of multi vm.

		traverse-perf-dir.sh -d ~/ceph-test-perf/
        
