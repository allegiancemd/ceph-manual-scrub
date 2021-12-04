## Configurations
We run a large ceph cluster, Ceph cluster falls behind deep scrubbing PGS on regular basis.

The idea is to run a cron script that orders the cluster to manual scrub PGS that fell behind, once caught up, go back 10 days and try to proactively scrub PGS 10 days or older (TIMELIMIT defaults to 10 days). We also set osd_deep_scrub_randomize_ratio = 0 to prevent the cluster to go back and scrub random PGS that aren't due and focus on the PGS that are falling behind or about to fall behind.

To overcome this problem, We had to change the following parameters

osd_deep_scrub_interval 1209600

_(osd_deep_scrub_randomize_ratio) This is very important setting, The default 0.15, i.e 15% of scrubbing is done on PGS on random basis. The rate at which scrubs will randomly become deep scrubs (even before osd_deep_scrub_interval has past)._

osd_deep_scrub_randomize_ratio=0

osd_max_scrubs=1

osd_scrub_load_threshold=3

osd_scrub_max_interval= 604800

osd_scrub_min_interval =  172800 ** Changed to 14 days

## To set via orchest
example
ceph config set osd osd_scrub_max_interval 604800



