/**
 *
 * Program that adds a CD-ROM drive via MountMgr.
 *
 * Note that the proper symlink should be under dosdevices. For example,
 * "$WINEPREFIX/dosdevices/d::" should point to "/dev/sr0".
 *
 * See https://github.com/wine-mirror/wine/blob/stable/programs/winecfg/drive.c
 */

#include <windows.h>

#include <wine/debug.h>

#define WINE_MOUNTMGR_EXTENSIONS
#include <ddk/mountmgr.h>

static HANDLE open_mountmgr(void)
{
    HANDLE ret;

    if ((ret = CreateFileW( MOUNTMGR_DOS_DEVICE_NAME, GENERIC_READ|GENERIC_WRITE,
                            FILE_SHARE_READ|FILE_SHARE_WRITE, NULL, OPEN_EXISTING,
                            0, 0 )) == INVALID_HANDLE_VALUE)
        printf("failed to open mount manager err %lu\n", GetLastError());
    return ret;
}

static void add_drive(char drive_letter, const char *unixpath)
{
    HANDLE mgr;
    DWORD len;
    DWORD type = DRIVE_CDROM;
    struct mountmgr_unix_drive *ioctl;

    if ((mgr = open_mountmgr()) == INVALID_HANDLE_VALUE) return;

    len = sizeof(*ioctl);
    len += strlen(unixpath) + 1;

    if (!(ioctl = malloc(len)))
    {
        printf("failed to alloc memory for ioctl\n");
    	CloseHandle(mgr);
        exit(1);
    }

    ioctl->size = len;
    ioctl->letter = drive_letter;
    ioctl->device_offset = 0;
    ioctl->type = type;

    char *ptr = (char *)(ioctl + 1);
    strcpy(ptr, unixpath);
    ioctl->mount_point_offset = ptr - (char *)ioctl;

    if (DeviceIoControl(mgr, IOCTL_MOUNTMGR_DEFINE_UNIX_DRIVE, ioctl, len, NULL, 0, NULL, NULL))
    {
        printf("set drive %c: to %s type %lu\n", drive_letter,
                    wine_dbgstr_a(unixpath), type);
    }
    else
    {
        printf("failed to set drive %c: to %s type %lu err %lu\n", drive_letter,
                wine_dbgstr_a(unixpath), type, GetLastError());
    }
    free(ioctl);
    CloseHandle(mgr);
}

static void usage(void)
{
    printf("Usage: add_cdrom_drive drive_letter\n"
           "Add a CD-ROM drive via MountMgr.\n");
}

int main(int argc, char** argv)
{
    char drive_letter = '\0';

    if (argc != 2)
    {
        usage();
        exit(1);
    }

    if (strlen(argv[1]) == 1)
    {
        drive_letter = argv[1][0];
    }
    else
    {
        printf("invalid drive letter\n");
        exit(1);
    }

    if (drive_letter >= 'A' && drive_letter <= 'Z')
    {
        drive_letter = tolower(drive_letter);
    }
    else if (drive_letter < 'a' || drive_letter > 'z')
    {
        printf("invalid drive letter\n");
        exit(1);
    }

    add_drive(drive_letter, "/");

    exit(0);
}
