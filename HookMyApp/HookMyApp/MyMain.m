//
//  HookMyApp
//
//  Created by gaoliutong on 2018/10/25.
//

#import <Foundation/Foundation.h>
#include <mach-o/dyld.h>
#include <dlfcn.h>
#import <UIKit/UIKit.h>
#import "CydiaSubstrate/CydiaSubstrate.h"

intptr_t g_slide;

//保存模块偏移基地址的值
static void _register_func_for_add_image(const struct mach_header *header, intptr_t slide) {
    Dl_info image_info;
    int result = dladdr(header, &image_info);
    if (result == 0) {
        NSLog(@"load mach_header failed");
        return;
    }
    //获取当前的可执行文件路径
    NSString *execName = [[[NSBundle mainBundle] infoDictionary] objectForKey:@"CFBundleExecutable"];
    NSString *execPath = [[[NSBundle mainBundle] bundlePath] stringByAppendingFormat:@"/%@", execName];
    if (strcmp([execPath UTF8String], image_info.dli_fname) == 0) {
        g_slide = slide;
    }
}

void (*orig_testMethod)(void);
void hook_testMethod(void);

//hook后会来到这里
void hook_testMethod(void) {
    UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"hook了我" message:@"message" delegate:nil cancelButtonTitle:nil otherButtonTitles:@"other", nil];
    [alert show];
}

static void __attribute__((constructor)) __init__() {
    //注册添加镜像回调
    _dyld_register_func_for_add_image(_register_func_for_add_image);
    //通过 模块偏移前的基地址 + ASLR偏移量 找到函数真正的地址进行hook
#warning 如果修改了MyApp工程的代码，此处的内存地址0x100006934需要改变，仅修改当前工程的代码，内存地址不需要改变
    MSHookFunction((void *)(0x100006934+g_slide), (void *)hook_testMethod, (void **)&orig_testMethod);
}
