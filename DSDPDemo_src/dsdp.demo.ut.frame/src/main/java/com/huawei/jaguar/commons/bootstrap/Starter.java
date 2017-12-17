package com.huawei.jaguar.commons.bootstrap;

import java.util.Date;

import org.springframework.beans.BeansException;
import org.springframework.context.ConfigurableApplicationContext;
import org.springframework.context.support.ClassPathXmlApplicationContext;

import com.huawei.bme.commons.om.log.DebugLog;
import com.huawei.bme.commons.om.log.LogFactory;
import com.huawei.bme.container.control.ContainerStateHolder;
import com.huawei.bme.container.control.ContextRegistry;
import com.huawei.jaguar.commons.bootstrap.control.ContainerControl;
import com.huawei.jaguar.commons.bootstrap.control.ContainerInfo;
import com.huawei.jaguar.commons.bootstrap.util.LogUtil;

/**
 * Digital SDP启动框架。配置文件包含spring启动前后的fixture启动和关闭顺序。
 * <功能详细描述>.
 * 
 * @author  g00129883
 * @version  [版本号, 2015年1月28日]
 * @see  [相关类/方法]
 * @since  [产品/模块版本]
 */
public class Starter
{
    
    /** The Constant logger. */
    private static final DebugLog logger = LogFactory.getDebugLog("DEP_STARTER_LOG");
    
    /** The container control. */
    private ContainerControl containerControl;
    
    /** The app context. */
    private ConfigurableApplicationContext appContext;
    
    /**
     * The main method.
     * 
     * @param args the args
     */
    public static void main(String[] args)
    {
        try
        {
            String startupPath = "classpath*:*.fixture.xml";
            System.setProperty("protostuff.runtime.collection_schema_on_repeated_fields", "true");
            System.setProperty("protostuff.runtime.morph_non_final_pojos", "true");
            
            final Starter starter = new Starter();
            starter.startup(new String[] {startupPath});
        }
        catch (BeansException e)
        {
            logger.error("Start application fail!", e);
        }
        
        logger.debug("Start application successfully!");
    }
    
    /**
     * 启动容器。.
     * 
     * @param configLocations Spring上下文配置的路径。如果为null则只使用平台默认的上下文配置
     * @return true, if startup
     */
    public boolean startup(String[] configLocations)
    {
        boolean isContextStarted = false;
        
        // 设置容器状态为正在初始化。
        ContainerStateHolder.setContainerState(ContainerStateHolder.INITIALIZING);
        try
        {
            // 创建控制器
            long beginTime = System.currentTimeMillis();
            System.out.println(LogUtil.paddingStr("", "", LogUtil.EQUAL, LogUtil.FROMAT_LENGTH));
            System.out.println(ContainerInfo.CONTAINER_STARTUP_INFO);
            
            // 创建装置控制器
            containerControl = new ContainerControl(null);
            
            // 加载需要在上下文之启动之前的组件
            containerControl.doBeforeContextLoad();
            
            // 初始化容器上下文
            long begin = System.currentTimeMillis();
            
            // 初始化Spring上下文
            appContext = new ClassPathXmlApplicationContext(configLocations);
            ContextRegistry.getContextHolder().setContext(appContext);
            appContext.registerShutdownHook();
            isContextStarted = true;
            
            long end = System.currentTimeMillis();
            
            System.out.println(LogUtil.paddingStr(ContainerInfo.CONTEXT_STARTSUCCESS_INFO,
                LogUtil.COST_STR.replaceAll(LogUtil.PERCENT, String.valueOf(end - begin)),
                LogUtil.DOT,
                LogUtil.FROMAT_LENGTH));
            
            // 加载需要在上下文之启动之后的组件
            containerControl.doAfterContextLoad();
            
            System.out.println(ContainerInfo.containerStartSuccess());
            
            long endTime = System.currentTimeMillis();
            long costTime = endTime - beginTime;
            
            System.out.println("Container startup cost " + costTime + " ms");
            System.out.println(LogUtil.paddingStr("", "", LogUtil.EQUAL, LogUtil.FROMAT_LENGTH));
            
            // 设置容器启动成功标志位
            ContainerStateHolder.setContainerState(ContainerStateHolder.STARTUP_SUCCESS);
            
            // 记录启动时刻
            com.huawei.bme.container.control.ContainerInfo.setStartTime(new Date());
            addShutdownHook();
            
            logger.info("Business Container Starting cost " + costTime + " ms");
            
            return true;
        }
        catch (Exception ex)
        {
            // 设置容器启动失败标志位
            ContainerStateHolder.setContainerState(ContainerStateHolder.STARTUP_FAILED);
            
            if (!isContextStarted)
            {
                System.out.println(LogUtil.paddingStr(ContainerInfo.CONTEXT_STARTFAIL_INFO,
                    "",
                    LogUtil.DOT,
                    LogUtil.FROMAT_LENGTH));
            }
            
            // 打印异常堆栈信息，在此不计日志
            ex.printStackTrace();
            
            // 如果在启动过程中捕获到异常，则直接关闭业务容器
            this.shutdown();
        }
        
        return false;
    }
    
    /**
     * Adds the shutdown hook.
     */
    private void addShutdownHook()
    {
        Runtime.getRuntime().addShutdownHook(new Thread(new Runnable()
        {
            @Override
            public void run()
            {
                logger.debug("Begin to shutdown");
                
                shutdown();
                
                logger.debug("Shutdown successfully!");
            }
        }));
    }
    
    /**
     * 关闭容器上下文。.
     * 
     */
    public void shutdown()
    {
        long beginTime = System.currentTimeMillis();
        System.out.println(ContainerInfo.CONTAINER_SHUTDOWN_INFO);
        
        // 关闭需要在容器上下文关闭之前的组件
        if (containerControl != null)
        {
            containerControl.doBeforeContextClose();
        }
        
        // 关闭容器上下文
        long begin = System.currentTimeMillis();
        if (appContext != null)
        {
            appContext.close();
            
            // 停止时只清除本身创建的应用上下文。
            ContextRegistry.getContextHolder().clearCtx(appContext);
        }
        
        long end = System.currentTimeMillis();
        
        System.out.println(LogUtil.paddingStr(ContainerInfo.CONTEXT_CLOSESUCCESS_INFO,
            LogUtil.COST_STR.replaceAll(LogUtil.PERCENT, String.valueOf(end - begin)),
            LogUtil.DOT,
            LogUtil.FROMAT_LENGTH));
        
        // 关闭需要在容器上下文之后的组件
        if (containerControl != null)
        {
            containerControl.doAfterContextClose();
        }
        
        System.out.println(ContainerInfo.containerShutDownSuccess());
        
        long endTime = System.currentTimeMillis();
        long costTime = endTime - beginTime;
        
        System.out.println("Container shutdown cost " + costTime + " ms");
        System.out.println(LogUtil.paddingStr("", "", LogUtil.EQUAL, LogUtil.FROMAT_LENGTH));
    }
}
