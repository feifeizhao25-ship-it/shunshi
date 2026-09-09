#!/usr/bin/env python3
"""Check the image, service, probes and SQLite storage as one contract.

Requires PyYAML. This is manifest validation, not a production rollout test.
"""
import json
from pathlib import Path
import sys

import yaml


def validate(root: Path) -> list[str]:
    def document(path):
        return yaml.safe_load((root / path).read_text())

    failures = []
    dockerfile = (root / "backend/Dockerfile").read_text().splitlines()
    workdir = next(line.split(maxsplit=1)[1] for line in dockerfile if line.startswith("WORKDIR "))
    command = json.loads(next(line[4:] for line in dockerfile if line.startswith("CMD ")))
    port = int(command[command.index("--port") + 1])
    deployment = document("k8s/backend-deployment.yaml")["spec"]
    pod = deployment["template"]["spec"]
    container = next(c for c in pod["containers"] if c["name"] == "backend")
    service = document("k8s/backend-service.yaml")["spec"]
    if not all(value == port for value in (
        container["ports"][0]["containerPort"], service["ports"][0]["targetPort"],
        container["readinessProbe"]["httpGet"]["port"], container["livenessProbe"]["httpGet"]["port"],
    )):
        failures.append("镜像监听端口、Service 和健康检查不一致")
    data = next(v for v in pod["volumes"] if v["name"] == "data")
    mount = next(v for v in container["volumeMounts"] if v["name"] == "data")
    pvc = document("k8s/backend-pvc.yaml")
    # COPY app ./app places app/database/db.py's data root in WORKDIR/data.
    if mount["mountPath"] != str(Path(workdir) / "data"):
        failures.append("SQLite 实际数据目录没有挂载数据卷")
    if data.get("persistentVolumeClaim", {}).get("claimName") != pvc["metadata"]["name"] or "emptyDir" in data:
        failures.append("订单数据卷必须引用持久卷")
    if pvc["spec"]["accessModes"] != ["ReadWriteOnce"]:
        failures.append("本地 SQLite 不允许多节点共享读写卷")
    hpa = document("k8s/hpa.yaml")["spec"]
    if deployment["replicas"] != 1 or hpa["minReplicas"] != 1 or hpa["maxReplicas"] != 1:
        failures.append("SQLite 迁移前必须限制为单副本")
    if deployment["strategy"]["type"] != "Recreate":
        failures.append("SQLite 持久卷不得由新旧 Pod 滚动并行使用")
    return failures


if __name__ == "__main__":
    errors = validate(Path(__file__).resolve().parents[1])
    if errors:
        sys.exit("后端部署契约检查失败：\n- " + "\n- ".join(errors))
    print("后端镜像端口、探针、持久卷和单副本约束检查通过")
