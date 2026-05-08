#include "campus_data.h"

void initCampusData(CampusGraph& graph) {
    // 添加16个景点
    graph.addSpot({0, "BCH", "百川河", 
        "校园内的景观河流，环境优美，是师生休闲散步的好去处。", 120, 280});
    
    graph.addSpot({1, "AQQ", "爱情桥", 
        "横跨百川河的景观桥，因浪漫氛围而得名，是校园标志性景点之一。", 180, 250});
    
    graph.addSpot({2, "ZCTC", "至诚体育场", 
        "大型综合体育场，可容纳数千人，是学校举办大型活动的主要场所。", 80, 180});
    
    graph.addSpot({3, "RACC", "仁爱操场", 
        "位于学生宿舍区附近的操场，方便学生日常锻炼。", 480, 380});
    
    graph.addSpot({4, "XYCC", "信义操场", 
        "另一处学生运动场地，设施完善，常有学生在此进行体育活动。", 580, 320});
    
    graph.addSpot({5, "TSG", "图书馆", 
        "学校的知识殿堂，藏书丰富，是学生自习和查阅资料的主要场所。", 380, 220});
    
    graph.addSpot({6, "YSGC", "仰山广场", 
        "校园中心广场，是学生活动和集会的重要场所，视野开阔。", 300, 180});
    
    graph.addSpot({7, "CXCY", "创新创业中心", 
        "支持学生创新创业的综合服务中心，提供项目孵化和指导服务。", 480, 120});
    
    graph.addSpot({8, "XSG", "校史馆", 
        "展示学校发展历程和辉煌成就的场馆，是了解学校历史的窗口。", 280, 120});
    
    graph.addSpot({9, "XZL", "行政楼", 
        "学校行政办公的主要场所，处理各类行政事务。", 200, 80});
    
    graph.addSpot({10, "HDG", "厚德馆", 
        "以'厚德'命名的教学楼，体现学校的育人理念。", 160, 180});
    
    graph.addSpot({11, "TGJX", "天工教学楼", 
        "主要教学楼之一，承担大量本科教学任务。", 280, 280});
    
    graph.addSpot({12, "MLJX", "明理教学楼", 
        "以'明理'命名的教学楼，是理工科课程的主要教学场所。", 400, 320});
    
    graph.addSpot({13, "ZSJC", "钻石剧场", 
        "学校的大型演出场馆，可举办各类文艺演出和学术报告。", 520, 200});
    
    graph.addSpot({14, "GJSY", "国家重点实验室", 
        "国家级科研平台，开展前沿科学研究，是学校科研实力的体现。", 580, 100});
    
    graph.addSpot({15, "ZQTG", "自强体育馆", 
        "室内综合体育馆，可进行篮球、羽毛球等多种室内运动。", 520, 380});

    // 添加道路连接
    graph.addEdge(0, 1, 80);
    graph.addEdge(0, 10, 100);
    graph.addEdge(0, 2, 150);
    graph.addEdge(1, 6, 100);
    graph.addEdge(1, 10, 80);
    graph.addEdge(2, 10, 120);
    graph.addEdge(2, 9, 150);
    graph.addEdge(3, 11, 150);
    graph.addEdge(3, 12, 120);
    graph.addEdge(3, 15, 130);
    graph.addEdge(4, 12, 100);
    graph.addEdge(4, 13, 150);
    graph.addEdge(4, 15, 80);
    graph.addEdge(5, 6, 100);
    graph.addEdge(5, 7, 120);
    graph.addEdge(5, 12, 100);
    graph.addEdge(5, 13, 130);
    graph.addEdge(6, 8, 80);
    graph.addEdge(6, 11, 120);
    graph.addEdge(7, 8, 180);
    graph.addEdge(7, 13, 100);
    graph.addEdge(7, 14, 120);
    graph.addEdge(8, 9, 80);
    graph.addEdge(8, 10, 120);
    graph.addEdge(9, 10, 130);
    graph.addEdge(10, 11, 150);
    graph.addEdge(11, 12, 120);
    graph.addEdge(12, 13, 130);
    graph.addEdge(12, 15, 100);
    graph.addEdge(13, 14, 100);
}
