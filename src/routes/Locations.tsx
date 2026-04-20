import { useEffect, useState } from 'react';
import { Plus, ChevronRight, ChevronDown, Edit2, Trash2, FolderOpen } from 'lucide-react';
import { useLocationStore } from '../stores/useLocationStore';
import ConfirmDialog from '../components/shared/ConfirmDialog';
import type { LocationTreeNode } from '../types/location';

export default function Locations() {
  const { locationTree, fetchLocations, addLocation, updateLocation, deleteLocation } = useLocationStore();
  const [addParentId, setAddParentId] = useState<string | null | 'root'>( null);
  const [newName, setNewName] = useState('');
  const [editId, setEditId] = useState<string | null>(null);
  const [editName, setEditName] = useState('');
  const [deleteId, setDeleteId] = useState<string | null>(null);

  useEffect(() => { fetchLocations(); }, [fetchLocations]);

  const handleAdd = async () => {
    if (!newName.trim()) return;
    await addLocation({
      name: newName.trim(),
      parent_id: addParentId === 'root' ? null : addParentId,
      image_path: '',
    });
    setNewName('');
    setAddParentId(null);
  };

  const handleUpdate = async () => {
    if (!editName.trim() || !editId) return;
    await updateLocation(editId, editName.trim());
    setEditId(null);
    setEditName('');
  };

  const handleDelete = async () => {
    if (deleteId) {
      await deleteLocation(deleteId);
      setDeleteId(null);
    }
  };

  return (
    <div className="p-4 md:p-6 max-w-2xl mx-auto max-md:pt-[calc(1rem+env(safe-area-inset-top,0px))]">
      <div className="flex items-center justify-between mb-5">
        <h1 className="text-xl font-bold text-gray-800">位置管理</h1>
        <button
          onClick={() => setAddParentId('root')}
          className="flex items-center gap-1.5 px-4 py-2.5 bg-primary text-white rounded-[12px] text-sm font-medium hover:opacity-90"
        >
          <Plus className="w-4 h-4" /> 添加位置
        </button>
      </div>

      {/* Add form */}
      {addParentId !== null && (
        <div className="bg-white rounded-[16px] p-4 border border-primary/30 mb-4">
          <p className="text-sm text-muted mb-2">
            {addParentId === 'root' ? '添加顶级位置' : '添加子位置'}
          </p>
          <div className="flex gap-2">
            <input
              type="text"
              value={newName}
              onChange={(e) => setNewName(e.target.value)}
              placeholder="位置名称"
              className="flex-1 px-3 py-2 bg-white border border-border rounded-[10px] text-sm outline-none focus:border-primary"
              autoFocus
              onKeyDown={(e) => e.key === 'Enter' && handleAdd()}
            />
            <button onClick={handleAdd} className="px-4 py-2 bg-primary text-white rounded-[10px] text-sm font-medium">
              添加
            </button>
            <button onClick={() => { setAddParentId(null); setNewName(''); }} className="px-3 py-2 border border-border rounded-[10px] text-sm text-gray-500">
              取消
            </button>
          </div>
        </div>
      )}

      {/* Tree */}
      <div className="space-y-1">
        {locationTree.length === 0 ? (
          <div className="text-center py-12 text-sm text-muted">
            <FolderOpen className="w-12 h-12 text-gray-200 mx-auto mb-3" />
            暂无位置，点击"添加位置"创建
          </div>
        ) : (
          locationTree.map((node) => (
            <LocationNode
              key={node.id}
              node={node}
              editId={editId}
              editName={editName}
              onAdd={(parentId) => setAddParentId(parentId)}
              onEditStart={(id, name) => { setEditId(id); setEditName(name); }}
              onEditNameChange={setEditName}
              onEditSave={handleUpdate}
              onEditCancel={() => { setEditId(null); setEditName(''); }}
              onDelete={setDeleteId}
            />
          ))
        )}
      </div>

      <ConfirmDialog
        open={Boolean(deleteId)}
        title="删除位置"
        message="删除此位置会同时删除所有子位置，已关联物品的位置将被清空。确定删除吗？"
        confirmLabel="删除"
        danger
        onConfirm={handleDelete}
        onCancel={() => setDeleteId(null)}
      />
    </div>
  );
}

function LocationNode({
  node, depth = 0, editId, editName,
  onAdd, onEditStart, onEditNameChange, onEditSave, onEditCancel, onDelete,
}: {
  node: LocationTreeNode;
  depth?: number;
  editId: string | null;
  editName: string;
  onAdd: (parentId: string) => void;
  onEditStart: (id: string, name: string) => void;
  onEditNameChange: (name: string) => void;
  onEditSave: () => void;
  onEditCancel: () => void;
  onDelete: (id: string) => void;
}) {
  const [expanded, setExpanded] = useState(true);
  const isEditing = editId === node.id;

  return (
    <div>
      <div
        className="flex items-center gap-2 bg-white rounded-[12px] p-3 border border-border/50 hover:border-gray-300 transition-colors"
        style={{ marginLeft: `${depth * 24}px` }}
      >
        <button
          onClick={() => setExpanded(!expanded)}
          className="p-0.5"
          disabled={node.children.length === 0}
        >
          {node.children.length > 0 ? (
            expanded ? <ChevronDown className="w-4 h-4 text-gray-400" /> : <ChevronRight className="w-4 h-4 text-gray-400" />
          ) : (
            <span className="w-4 h-4 block" />
          )}
        </button>

        {isEditing ? (
          <div className="flex-1 flex gap-2">
            <input
              type="text"
              value={editName}
              onChange={(e) => onEditNameChange(e.target.value)}
              className="flex-1 px-2 py-1 border border-primary rounded-lg text-sm outline-none"
              autoFocus
              onKeyDown={(e) => { if (e.key === 'Enter') onEditSave(); if (e.key === 'Escape') onEditCancel(); }}
            />
            <button onClick={onEditSave} className="px-3 py-1 bg-primary text-white rounded-lg text-xs">保存</button>
            <button onClick={onEditCancel} className="px-3 py-1 border border-border rounded-lg text-xs text-gray-500">取消</button>
          </div>
        ) : (
          <>
            <FolderOpen className="w-4 h-4 text-primary/60 shrink-0" />
            <span className="flex-1 text-sm text-gray-800">{node.name}</span>
            <div className="flex gap-0.5 opacity-0 group-hover:opacity-100">
              <button onClick={() => onAdd(node.id)} className="p-1.5 rounded-lg hover:bg-gray-100" title="添加子位置">
                <Plus className="w-3.5 h-3.5 text-gray-400" />
              </button>
              <button onClick={() => onEditStart(node.id, node.name)} className="p-1.5 rounded-lg hover:bg-gray-100">
                <Edit2 className="w-3.5 h-3.5 text-gray-400" />
              </button>
              <button onClick={() => onDelete(node.id)} className="p-1.5 rounded-lg hover:bg-red-50">
                <Trash2 className="w-3.5 h-3.5 text-gray-400" />
              </button>
            </div>
          </>
        )}
      </div>

      {expanded && node.children.map((child) => (
        <LocationNode
          key={child.id}
          node={child}
          depth={depth + 1}
          editId={editId}
          editName={editName}
          onAdd={onAdd}
          onEditStart={onEditStart}
          onEditNameChange={onEditNameChange}
          onEditSave={onEditSave}
          onEditCancel={onEditCancel}
          onDelete={onDelete}
        />
      ))}
    </div>
  );
}
